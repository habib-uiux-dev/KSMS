import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/user_filter.dart';
import '../../../core/services/firebase/app_firestore.dart';
import '../../auth/model/app_user.dart';
import '../model/chat_conversation.dart';
import '../model/chat_message.dart';
import 'chat_notification_sender.dart';

/// Manages Firestore operations for 1-on-1 real-time chats.
class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  /// Generates a deterministic chat ID for two user UIDs.
  static String getChatId(String uid1, String uid2) =>
      ChatConversation.makeChatId(uid1, uid2);

  /// Real-time stream of all registered users from the `users` collection.
  Stream<List<AppUser>> streamAllUsers({String? excludeUid}) {
    return _db.collection('users').snapshots().map((snapshot) {
      final list = <AppUser>[];
      for (final doc in snapshot.docs) {
        if (excludeUid != null && doc.id == excludeUid) continue;
        try {
          final user = AppUser.fromDoc(doc);
          if (UserFilter.isExcluded(
            uid: user.uid,
            name: user.name,
            email: user.email,
          )) {
            continue;
          }
          list.add(user);
        } catch (e) {
          log('Error parsing user ${doc.id}: $e');
        }
      }
      return list;
    });
  }

  /// Real-time stream of all chat conversations for the current user.
  Stream<List<ChatConversation>> streamUserChats(String currentUid) {
    return _chats
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
          final chats = <ChatConversation>[];
          for (final doc in snapshot.docs) {
            try {
              chats.add(ChatConversation.fromDoc(doc));
            } catch (e) {
              log('Error parsing chat ${doc.id}: $e');
            }
          }
          // Sort by last message time descending
          chats.sort((a, b) {
            final tA = a.lastMessageTime ?? a.updatedAt;
            final tB = b.lastMessageTime ?? b.updatedAt;
            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });
          return chats;
        });
  }

  /// Real-time stream of messages in a 1-on-1 chat ordered by timestamp.
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _messages(chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromDoc(doc))
              .toList();
        });
  }

  /// Sends a message and updates the parent conversation in real-time.
  /// Also sends a targeted FCM push notification to the recipient.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhoto,
    String? senderEmail,
    required AppUser recipient,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final messageRef = _messages(chatId).doc();
    final messageId = messageRef.id;

    final messageData = {
      'id': messageId,
      'sender_id': senderId,
      'receiver_id': recipient.uid,
      'text': cleanText,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
      'read_at': null,
    };

    final chatRef = _chats.doc(chatId);

    final sortedParticipants = [senderId, recipient.uid]..sort();

    final chatUpdateData = {
      'chat_id': chatId,
      'participants': sortedParticipants,
      'participant_names': {
        senderId: senderName,
        recipient.uid: recipient.name ?? recipient.email ?? 'User',
      },
      'participant_photos': {
        senderId: senderPhoto ?? '',
        recipient.uid: recipient.photoUrl ?? '',
      },
      'participant_emails': {
        senderId: senderEmail ?? '',
        recipient.uid: recipient.email ?? '',
      },
      'last_message': cleanText,
      'last_message_sender_id': senderId,
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_counts': {
        senderId: 0,
        recipient.uid: FieldValue.increment(1),
      },
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Use WriteBatch for atomic message write + conversation update
    final batch = _db.batch();
    batch.set(messageRef, messageData);
    batch.set(chatRef, chatUpdateData, SetOptions(merge: true));
    await batch.commit();

    // Trigger targeted push notification strictly to the recipient
    unawaited(
      ChatNotificationSender.sendChatMessageNotification(
        recipientUid: recipient.uid,
        senderName: senderName,
        messageText: cleanText,
        chatId: chatId,
      ),
    );
  }

  /// Marks all unread messages received by [currentUid] in [chatId] as read.
  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUid,
  }) async {
    try {
      final unreadDocs = await _messages(chatId)
          .where('receiver_id', isEqualTo: currentUid)
          .where('is_read', isEqualTo: false)
          .get();

      if (unreadDocs.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in unreadDocs.docs) {
          batch.update(doc.reference, {
            'is_read': true,
            'read_at': FieldValue.serverTimestamp(),
          });
        }
        // Also reset unread_counts for this user
        batch.set(
          _chats.doc(chatId),
          {
            'unread_counts': {currentUid: 0},
          },
          SetOptions(merge: true),
        );
        await batch.commit();
      } else {
        // Just ensure unread count is 0
        await _chats.doc(chatId).set(
          {
            'unread_counts': {currentUid: 0},
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      log('ChatService.markMessagesAsRead error: $e');
    }
  }
}
