import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

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

  /// Sends a notification to everyone, and returns null on success or a
  /// human-readable reason on failure.
  ///
  /// Errors come back as a string rather than an exception because every
  /// caller wants to put them on screen, and the FCM error body is the only
  /// place that says *why* a send was refused.
  static Future<String?> sendToEveryone({
    required String title,
    required String body,
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
            'notification': {'title': title, 'body': body},
            // high priority so Android wakes the device rather than batching
            // this with tomorrow's sync.
            //
            // The channel id must match the one AwesomeNotificationService
            // registers, or a notification arriving while the app is killed
            // lands on Android's default channel with no sound.
            'android': {
              'priority': 'high',
              'notification': {'channel_id': 'main_channel'},
            },
            'apns': {
              'headers': {'apns-priority': '10'},
            },
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
