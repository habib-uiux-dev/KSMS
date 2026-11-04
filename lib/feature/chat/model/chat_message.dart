import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message in the 1-on-1 chat subcollection `chats/{chatId}/messages/{messageId}`.
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime? timestamp;
  final bool isRead;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.timestamp,
    this.isRead = false,
    this.readAt,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
  }) => ChatMessage(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    receiverId: receiverId ?? this.receiverId,
    text: text ?? this.text,
    timestamp: timestamp ?? this.timestamp,
    isRead: isRead ?? this.isRead,
    readAt: readAt ?? this.readAt,
  );

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ChatMessage(
      id: id,
      senderId: (map['sender_id'] ?? map['senderId'] ?? '').toString(),
      receiverId: (map['receiver_id'] ?? map['receiverId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      timestamp: parseDate(map['timestamp']),
      isRead: map['is_read'] == true || map['isRead'] == true,
      readAt: parseDate(map['read_at'] ?? map['readAt']),
    );
  }

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ChatMessage.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
    'is_read': isRead,
    if (readAt != null) 'read_at': Timestamp.fromDate(readAt!),
  };
}
