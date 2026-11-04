import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/user_filter.dart';
import '../../auth/model/app_user.dart';
import '../model/chat_conversation.dart';
import '../services/chat_service.dart';

/// State management for ChatListScreen.
class ChatListController extends GetxController {
  ChatListController({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  final users = <AppUser>[].obs;
  final chats = <ChatConversation>[].obs;
  final chatMap = <String, ChatConversation>{}.obs;

  final isLoadingUsers = true.obs;
  final isLoadingChats = true.obs;
  final searchQuery = ''.obs;

  final searchController = TextEditingController();

  StreamSubscription<List<AppUser>>? _usersSub;
  StreamSubscription<List<ChatConversation>>? _chatsSub;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _listenToUsers();
    _listenToChats();
  }

  @override
  void onClose() {
    _usersSub?.cancel();
    _chatsSub?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _listenToUsers() {
    final uid = currentUid;
    _usersSub = _chatService.streamAllUsers(excludeUid: uid).listen(
      (userList) {
        users.assignAll(
          userList.where((u) => !UserFilter.isExcluded(
            uid: u.uid,
            name: u.name,
            email: u.email,
          )),
        );
        isLoadingUsers.value = false;
      },
      onError: (e) {
        isLoadingUsers.value = false;
      },
    );
  }

  void _listenToChats() {
    final uid = currentUid;
    if (uid == null) {
      isLoadingChats.value = false;
      return;
    }

    _chatsSub = _chatService.streamUserChats(uid).listen(
      (chatList) {
        chats.assignAll(chatList);
        final map = <String, ChatConversation>{};
        for (final chat in chatList) {
          final otherUid = chat.getOtherUserId(uid);
          if (otherUid.isNotEmpty) {
            map[otherUid] = chat;
          }
        }
        chatMap.assignAll(map);
        isLoadingChats.value = false;
      },
      onError: (e) {
        isLoadingChats.value = false;
      },
    );
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  List<AppUser> get filteredUsers {
    final query = searchQuery.value.trim().toLowerCase();
    var list = users
        .where((u) => !UserFilter.isExcluded(
              uid: u.uid,
              name: u.name,
              email: u.email,
            ))
        .toList();

    if (query.isNotEmpty) {
      list = list.where((u) {
        final name = (u.name ?? '').toLowerCase();
        final email = (u.email ?? '').toLowerCase();
        final designation = (u.designation ?? '').toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            designation.contains(query);
      }).toList();
    }

    // Sort: users with active conversations and most recent message first,
    // followed by other users alphabetically by name.
    list.sort((a, b) {
      final chatA = chatMap[a.uid];
      final chatB = chatMap[b.uid];
      final timeA = chatA?.lastMessageTime ?? chatA?.updatedAt;
      final timeB = chatB?.lastMessageTime ?? chatB?.updatedAt;

      if (timeA != null && timeB != null) {
        return timeB.compareTo(timeA);
      }
      if (timeA != null) return -1;
      if (timeB != null) return 1;

      final nameA = (a.name ?? a.email ?? '').toLowerCase();
      final nameB = (b.name ?? b.email ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return list;
  }

  ChatConversation? getChatForUser(String otherUid) {
    final direct = chatMap[otherUid];
    if (direct != null) return direct;
    final myId = currentUid;
    if (myId == null) return null;
    final targetId = ChatService.getChatId(myId, otherUid);
    for (final c in chats) {
      if (c.chatId == targetId) return c;
    }
    return null;
  }

  /// WhatsApp-like relative timestamp formatting.
  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final difference = now.difference(local);

    final sameDay =
        now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;

    if (sameDay) {
      return DateFormat('hh:mm a').format(local);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday =
        yesterday.year == local.year &&
        yesterday.month == local.month &&
        yesterday.day == local.day;

    if (wasYesterday) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(local); // e.g. "Monday"
    }

    return DateFormat('dd/MM/yy').format(local);
  }
}
