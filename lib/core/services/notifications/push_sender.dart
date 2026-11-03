import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

import '../firebase/app_firestore.dart';
import '../firebase/user_repository.dart';

/// One device that did not get the message, and why.
typedef PushFailure = ({String name, String reason});

/// What actually happened when a notification went out.
///
/// The whole point of sending per device rather than to a topic: this can say
/// "10 of 12", and name the two.
class PushReport {
  const PushReport({required this.delivered, required this.failures});

  final int delivered;
  final List<PushFailure> failures;

  int get attempted => delivered + failures.length;

  bool get isCompleteSuccess => failures.isEmpty && delivered > 0;
}

/// Sends a push notification straight from the admin's phone.
///
/// Normally this belongs on a server, because signing an FCM request needs a
/// service-account key and a key inside an APK is a key anyone can unzip out
/// of it. That was a deliberate trade here: the app is used by a handful of
/// colleagues, and standing up a server to send four notifications a month was
/// not worth it.
///
/// The mitigation that makes it acceptable is the key's *scope*. It must be a
/// service account holding ONLY the Cloud Messaging role - see
/// assets/secrets/fcm_service_account.json.example. Then the worst anyone can
/// do with a stolen copy is send notifications to this app, rather than read
/// and delete the whole database.
class PushSender {
  PushSender._();

  static const String _keyAsset = 'assets/secrets/fcm_service_account.json';

  /// The topic every installed app subscribes to on launch.
  static const String allUsersTopic = 'all_users';

  /// Sending is the only thing this key is for. Asking for anything wider
  /// would be a bigger blast radius for no benefit.
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  /// Held between sends because the OAuth token is good for an hour and
  /// re-signing a JWT per notification is pure waste.
  static AutoRefreshingAuthClient? _client;
  static String? _projectId;

  /// True when the key file has been dropped in. The admin screen checks this
  /// so it can explain what is missing instead of failing on the first tap.
  static Future<bool> isConfigured() async {
    try {
      final raw = await rootBundle.loadString(_keyAsset);
      return !raw.contains('PUT_YOURS_HERE');
    } catch (_) {
      return false;
    }
  }

  /// Sends to every registered device, one request each, and reports what
  /// happened to each.
  ///
  /// One request per token rather than the topic, because a topic send returns
  /// a single "accepted" and nothing else - not who is subscribed, not who
  /// received it, not who has uninstalled. Addressing devices individually is
  /// the only way FCM will tell you that four of twelve failed, and why.
  ///
  /// Requests go out in small batches: sequential would take a noticeable
  /// pause on a phone with a slow connection, and all-at-once opens a socket
  /// per colleague for no gain.
  static Future<PushReport> sendToDevices({
    required List<PushTarget> targets,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    if (targets.isEmpty) {
      return const PushReport(delivered: 0, failures: []);
    }

    final client = await _authorised();
    if (client == null) {
      return PushReport(
        delivered: 0,
        failures: [
          for (final target in targets)
            (name: target.name, reason: 'Sender key missing'),
        ],
      );
    }

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
    );
    final payload = _payload(title: title, body: body, imageUrl: imageUrl);

    var delivered = 0;
    final failures = <PushFailure>[];

    const batchSize = 5;
    for (var i = 0; i < targets.length; i += batchSize) {
      final batch = targets.skip(i).take(batchSize);

      final results = await Future.wait(
        batch.map((target) async {
          try {
            final response = await client.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': {'token': target.token, ...payload},
              }),
            );

            if (response.statusCode == 200) return null;

            log('FCM to ${target.name} failed '
                '${response.statusCode}: ${response.body}');
            return (
              name: target.name,
              reason: _perDeviceReason(response.statusCode, response.body),
            );
          } catch (e) {
            log('FCM to ${target.name} failed: $e');
            return (name: target.name, reason: 'No connection');
          }
        }),
      );

      for (final failure in results) {
        if (failure == null) {
          delivered++;
        } else {
          failures.add(failure);
        }
      }
    }

    return PushReport(delivered: delivered, failures: failures);
  }

  /// Sends to everyone, and returns null on success or a human-readable reason
  /// on failure.
  ///
  /// Kept as the fallback for when nobody has registered a token yet - the
  /// first launch after this feature shipped, when the only thing every phone
  /// has in common is the topic subscription.
  ///
  /// Errors come back as a string rather than an exception because every
  /// caller wants to put them on screen, and the FCM error body is the only
  /// place that says *why* a send was refused.
  static Future<String?> sendToEveryone({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final client = await _authorised();
      if (client == null) {
        return 'The sender key is missing. See '
            'assets/secrets/fcm_service_account.json.example';
      }

      final response = await client.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': {
            'topic': allUsersTopic,
            ..._payload(title: title, body: body, imageUrl: imageUrl),
          },
        }),
      );

      if (response.statusCode == 200) return null;

      log('FCM send failed ${response.statusCode}: ${response.body}');
      return _explain(response.statusCode, response.body);
    } catch (e) {
      log('FCM send failed: $e');
      return 'Could not send. Check the internet connection.';
    }
  }

  /// Broadcasts notification to all registered devices or all_users topic.
  static Future<PushReport> broadcast({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final targets = await UserRepository().fetchPushTargets();
      if (targets.isNotEmpty) {
        return await sendToDevices(
          targets: targets,
          title: title,
          body: body,
          imageUrl: imageUrl,
        );
      } else {
        final err = await sendToEveryone(
          title: title,
          body: body,
          imageUrl: imageUrl,
        );
        return PushReport(
          delivered: err == null ? 1 : 0,
          failures: err == null ? [] : [(name: 'Everyone', reason: err)],
        );
      }
    } catch (e) {
      log('PushSender.broadcast error: $e');
      return PushReport(delivered: 0, failures: [(name: 'All', reason: '$e')]);
    }
  }

  /// Sends a push notification to specific users by ID, UID, email, or name.
  static Future<PushReport> sendToUsers({
    required Iterable<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    final rawSelectedIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (rawSelectedIds.isEmpty) {
      return const PushReport(delivered: 0, failures: []);
    }

    final resolvedUids = <String>{...rawSelectedIds};
    try {
      final allUserDocs = await appFirestore.collection('users').get();
      for (final uDoc in allUserDocs.docs) {
        final uData = uDoc.data();
        if (UserRepository.matchesUser(
          allowedIdentifiers: rawSelectedIds,
          docId: uDoc.id,
          data: uData,
        )) {
          resolvedUids.add(uDoc.id);
          final customId = uData['id']?.toString().trim();
          final authUid = uData['uid']?.toString().trim();
          final email = uData['email']?.toString().trim();
          final name = uData['name']?.toString().trim();
          if (customId != null && customId.isNotEmpty) resolvedUids.add(customId);
          if (authUid != null && authUid.isNotEmpty) resolvedUids.add(authUid);
          if (email != null && email.isNotEmpty) resolvedUids.add(email);
          if (name != null && name.isNotEmpty) resolvedUids.add(name);
        }
      }
    } catch (e) {
      log('Could not resolve user aliases: $e');
    }

    final targets =
        await UserRepository().fetchPushTargets(allowedUids: resolvedUids);
    if (targets.isEmpty) {
      log('PushSender.sendToUsers: no push targets found for $resolvedUids');
      return const PushReport(delivered: 0, failures: []);
    }

    return await sendToDevices(
      targets: targets,
      title: title,
      body: body,
      imageUrl: imageUrl,
    );
  }

  /// Everything in a message except who it goes to.
  ///
  /// [imageUrl] must be a public http(s) link. FCM fetches it on its own
  /// servers, not on the phone, so anything behind a login or reachable only
  /// on the office network arrives as a notification with no picture and no
  /// error to say why.
  static Map<String, dynamic> _payload({
    required String title,
    required String body,
    String? imageUrl,
  }) => {
    'notification': {'title': title, 'body': body, 'image': ?imageUrl},
    // high priority so Android wakes the device rather than batching this
    // with tomorrow's sync.
    //
    // The channel id must match the one MainActivity creates and the manifest
    // declares, or a notification arriving while the app is killed has
    // nowhere to land.
    'android': {
      'priority': 'high',
      'notification': {
        'channel_id': 'main_channel',
        // Repeated here on purpose: the top-level `image` is what the system
        // tray uses when the app is closed, and this one is what arrives as
        // message.notification.android.imageUrl for the foreground handler to
        // draw itself.
        'image': ?imageUrl,
      },
    },
    'apns': {
      'headers': {'apns-priority': '10'},
      if (imageUrl != null) 'fcm_options': {'image': imageUrl},
    },
  };

  /// Why one particular phone did not get it.
  ///
  /// UNREGISTERED is the interesting one and by far the most common: the app
  /// was uninstalled, or its data cleared, and the token now points at
  /// nothing. It fixes itself the next time that person opens the app, which
  /// is why nothing here tries to delete the stale token - an admin cannot
  /// write to someone else's user document anyway.
  static String _perDeviceReason(int status, String body) {
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
      final detail = error?['status'] as String?;
      if (detail == 'NOT_FOUND' || detail == 'UNREGISTERED') {
        return 'App removed or reinstalled';
      }
      if (detail == 'INVALID_ARGUMENT') return 'Device registration is stale';
      if (detail == 'PERMISSION_DENIED') return 'Sender key lacks permission';
      if (detail == 'UNAVAILABLE') return 'FCM was busy - try again';
      final message = error?['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // Not JSON - fall through rather than showing a proxy's HTML.
    }
    if (status == 404) return 'App removed or reinstalled';
    return 'Failed ($status)';
  }

  static Future<AutoRefreshingAuthClient?> _authorised() async {
    if (_client != null) return _client;

    final String raw;
    try {
      raw = await rootBundle.loadString(_keyAsset);
    } catch (_) {
      return null;
    }
    if (raw.contains('PUT_YOURS_HERE')) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    _projectId = json['project_id'] as String?;

    _client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(json),
      _scopes,
    );
    return _client;
  }

  /// Turns FCM's JSON error into something an admin can act on.
  static String _explain(int status, String body) {
    if (status == 401 || status == 403) {
      return 'The sender key was rejected. It needs the '
          '"Firebase Cloud Messaging API Admin" role.';
    }
    if (status == 404) {
      return 'Project not found - check project_id in the key file.';
    }
    try {
      final message =
          (jsonDecode(body) as Map<String, dynamic>)['error']?['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {
      // Not JSON. Fall through to the generic line rather than showing the
      // raw HTML of some proxy's error page.
    }
    return 'Send failed ($status)';
  }

  /// Drops the cached client. Only needed if the key is replaced at runtime,
  /// which in practice means a rebuild - kept for tests.
  static void reset() {
    _client?.close();
    _client = null;
    _projectId = null;
  }
}
