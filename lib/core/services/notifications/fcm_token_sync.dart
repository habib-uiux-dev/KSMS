import 'dart:async';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase/user_repository.dart';

/// Keeps `users/{uid}.fcm_token` pointing at the device this person is holding.
///
/// The token is what makes a notification addressable. Without it the only way
/// to reach anyone was the `all_users` topic, which is write-only in the worst
/// sense: nothing reports who is subscribed, or whether a message arrived, so
/// "some phones get it and some don't" had no way of being investigated except
/// borrowing each phone in turn.
///
/// A token is per install, not per person: it changes on reinstall, on clearing
/// app data, and occasionally on its own. So this runs on every launch rather
/// than once at sign-up, and listens for refreshes for as long as the session
/// lasts.
class FcmTokenSync {
  FcmTokenSync._();

  static StreamSubscription<String>? _refreshSub;
  static String? _lastWritten;

  /// Call once the signed-in uid is known.
  ///
  /// Failures are logged and swallowed. A token that did not save costs one
  /// person one notification; an exception here would cost them the home
  /// screen.
  static Future<void> start(String uid, {UserRepository? repository}) async {
    final users = repository ?? UserRepository();

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _write(users, uid, token);
      }
    } catch (e) {
      log('Could not save the FCM token: $e');
    }

    _refreshSub?.cancel();
    _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _write(users, uid, token),
      onError: (Object e) => log('Token refresh stream failed: $e'),
    );
  }

  /// Skips the write when nothing changed. Tokens are stable for weeks, and
  /// this runs on every launch - without the guard it would be a Firestore
  /// write per app open, per person, forever.
  static Future<void> _write(
    UserRepository users,
    String uid,
    String token,
  ) async {
    if (token == _lastWritten) return;
    try {
      await users.saveFcmToken(uid, token);
      _lastWritten = token;
      log('FCM token saved for $uid');
    } catch (e) {
      log('Could not save the FCM token: $e');
    }
  }

  /// Called on sign-out so the next person's token is not compared against the
  /// previous one and skipped.
  static Future<void> stop() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    _lastWritten = null;
  }
}
