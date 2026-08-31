import 'package:awesome_notifications/awesome_notifications.dart';

class AwesomeNotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'main_channel',
        channelName: 'Main Channel',
        channelDescription: 'App notifications',
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
        criticalAlerts: true,
      ),
    ], debug: true);

    // Ask notification permission (Android 13+ / iOS)
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,

    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'main_channel',
        title: title,
        body: body,
        notificationLayout: imageUrl != null
            ? NotificationLayout.BigPicture
            : NotificationLayout.Default,

        bigPicture: imageUrl,
        largeIcon: imageUrl,

        payload: payload,
      ),
    );
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // print(receivedAction.payload);
  }
}
