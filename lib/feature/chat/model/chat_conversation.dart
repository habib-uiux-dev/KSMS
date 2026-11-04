import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a 1-on-1 chat thread between two users in `chats/{chatId}`.
class ChatConversation {
  final String chatId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final Map<String, String> participantEmails;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts;
  final DateTime? updatedAt;

  const ChatConversation({
    required this.chatId,
    required this.participants,
    this.participantNames = const {},
    this.participantPhotos = const {},
    this.participantEmails = const {},
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    this.lastMessageTime,
    this.unreadCounts = const {},
    this.updatedAt,
  });

  /// Deterministic chat ID between two user IDs (order independent).
  static String makeChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  String getOtherUserId(String myUid) {
    final match = participants.firstWhere((id) => id != myUid, orElse: () => '');
    if (match.isNotEmpty) return match;
    final parts = chatId.split('_');
    if (parts.length == 2) {
      if (parts[0] == myUid) return parts[1];
      if (parts[1] == myUid) return parts[0];
    }
    return '';
  }

  String getOtherUserName(String myUid) {
    final otherUid = getOtherUserId(myUid);
    return participantNames[otherUid] ?? 'User';
  }

  String? getOtherUserPhoto(String myUid) {
    final otherUid = getOtherUserId(myUid);
    final photo = participantPhotos[otherUid];
    return (photo != null && photo.isNotEmpty) ? photo : null;
  }

  String? getOtherUserEmail(String myUid) {
    final otherUid = getOtherUserId(myUid);
    final email = participantEmails[otherUid];
    return (email != null && email.isNotEmpty) ? email : null;
  }

  int getUnreadCount(String myUid) {
    return unreadCounts[myUid] ?? 0;
  }

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawParticipants = map['participants'] as List? ?? [];
    final participants = rawParticipants.map((e) => e.toString()).toList();

    Map<String, String> parseStringMap(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
      }
      return {};
    }

    Map<String, int> parseIntMap(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) {
          final count = v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
          return MapEntry(k.toString(), count);
        });
      }
      return {};
    }

    return ChatConversation(
      chatId: id,
      participants: participants,
      participantNames: parseStringMap(map['participant_names']),
      participantPhotos: parseStringMap(map['participant_photos']),
      participantEmails: parseStringMap(map['participant_emails']),
      lastMessage: (map['last_message'] ?? '').toString(),
      lastMessageSenderId: (map['last_message_sender_id'] ?? '').toString(),
      lastMessageTime: parseDate(map['last_message_time']),
      unreadCounts: parseIntMap(map['unread_counts']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  factory ChatConversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ChatConversation.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
    'chat_id': chatId,
    'participants': participants,
    'participant_names': participantNames,
    'participant_photos': participantPhotos,
    'participant_emails': participantEmails,
    'last_message': lastMessage,
    'last_message_sender_id': lastMessageSenderId,
    'last_message_time': FieldValue.serverTimestamp(),
    'unread_counts': unreadCounts,
    'updated_at': FieldValue.serverTimestamp(),
  };
}
