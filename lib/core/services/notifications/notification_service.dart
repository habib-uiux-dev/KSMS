import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'awesome_notification_service.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const Duration _networkTimeout = Duration(seconds: 10);

  static bool _isSubscribed = false;

  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  static Future<void> initialize() async {
    // Request notification permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        log("✅ Notification permission granted");
        break;

      case AuthorizationStatus.provisional:
        log("✅ Provisional notification permission granted");
        break;

      case AuthorizationStatus.denied:
        log("❌ Notification permission denied");
        return;

      case AuthorizationStatus.deniedPermanently:
        log("❌ Notification permission permanently denied");
        return;

      case AuthorizationStatus.notDetermined:
        log("Notification permission not determined");
        return;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    /// Foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        AwesomeNotificationService.showNotification(
          title: message.notification?.title ?? "",
          body: message.notification?.body ?? "",
          imageUrl:
              message.notification?.android?.imageUrl ?? message.data['image'],
          payload: message.data.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }
    });

    /// Notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("Notification opened: ${message.data}");
    });

    /// Get FCM token
    await getToken();

    /// Try subscribing immediately
    await trySubscribeTopic();

    /// Retry when internet comes back
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen((
      _,
    ) async {
      await trySubscribeTopic();
    });

    /// Re-subscribe if Firebase generates a new token
    _messaging.onTokenRefresh.listen((token) async {
      log("FCM Token refreshed: $token");

      _isSubscribed = false;

      await trySubscribeTopic();
    });
  }

  static Future<void> getToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken().timeout(
          _networkTimeout,
        );

        log("APNS Token: $apnsToken");
      }

      final token = await _messaging.getToken().timeout(_networkTimeout);

      if (token == null) {
        log("❌ FCM token is null");
        return;
      }

      log("FCM Token: $token");
      // Send token to your backend
      // appData.write(kKeyFCMToken, token);
    } catch (e) {
      log("Error getting FCM token: $e");
    }
  }

  static Future<void> trySubscribeTopic() async {
    if (_isSubscribed) {
      return;
    }

    try {
      await _messaging.subscribeToTopic("all_users").timeout(_networkTimeout);

      _isSubscribed = true;

      log("✅ Successfully subscribed to topic: all_users");
    } catch (e) {
      log("❌ Topic subscription failed: $e");
    }
  }

  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
