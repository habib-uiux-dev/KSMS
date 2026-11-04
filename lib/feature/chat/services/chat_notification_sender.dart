import 'dart:developer';

import '../../../core/services/firebase/app_firestore.dart';
import '../../../core/services/notifications/push_sender.dart';

/// Sends targeted 1-on-1 FCM push notifications for new chat messages.
class ChatNotificationSender {
  ChatNotificationSender._();

  /// Sends an FCM Push Notification ONLY to the recipient user.
  ///
  /// [senderName] is used as the notification title.
  /// [messageText] is used as the notification body.
  /// Only [recipientUid] receives this notification.
  static Future<void> sendChatMessageNotification({
    required String recipientUid,
    required String senderName,
    required String messageText,
    String? chatId,
  }) async {
    try {
      final trimmedRecipientUid = recipientUid.trim();
      if (trimmedRecipientUid.isEmpty) return;

      // 1. Direct targeted lookup from recipient's user document
      final userDoc = await appFirestore
          .collection('users')
          .doc(trimmedRecipientUid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final token = (data['fcm_token'] ?? data['fcmToken'])?.toString().trim();
        final recipientName =
            (data['name'] ?? data['displayName'] ?? 'Colleague').toString();

        if (token != null && token.isNotEmpty) {
          final target = (
            uid: trimmedRecipientUid,
            name: recipientName,
            token: token,
          );

          final report = await PushSender.sendToDevices(
            targets: [target],
            title: senderName.trim().isEmpty ? 'New Message' : senderName.trim(),
            body: messageText,
          );

          log('Chat notification sent to $trimmedRecipientUid: delivered=${report.delivered}');
          return;
        }
      }

      // 2. Fallback to sendToUsers matching ONLY this recipient UID
      final report = await PushSender.sendToUsers(
        userIds: [trimmedRecipientUid],
        title: senderName.trim().isEmpty ? 'New Message' : senderName.trim(),
        body: messageText,
      );
      log('Fallback chat notification to $trimmedRecipientUid: delivered=${report.delivered}');
    } catch (e) {
      log('ChatNotificationSender.sendChatMessageNotification failed: $e');
    }
  }
}
