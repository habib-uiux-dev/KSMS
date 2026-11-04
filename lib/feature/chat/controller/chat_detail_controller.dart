import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/show_custom_toast.dart';
import '../../auth/model/app_user.dart';
import '../model/chat_message.dart';
import '../services/chat_service.dart';

/// State management for ChatDetailScreen (1-on-1 Inbox).
class ChatDetailController extends GetxController {
  ChatDetailController({
    AppUser? recipient,
    ChatService? chatService,
  }) : _initialRecipient = recipient,
       _chatService = chatService ?? ChatService();

  final AppUser? _initialRecipient;
  final ChatService _chatService;

  final recipient = Rxn<AppUser>();
  final messages = <ChatMessage>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;

  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final focusNode = FocusNode();

  final showEmoji = false.obs;

  StreamSubscription<List<ChatMessage>>? _messagesSub;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  late final String chatId;

  @override
  void onInit() {
    super.onInit();
    focusNode.addListener(() {
      if (focusNode.hasFocus && showEmoji.value) {
        showEmoji.value = false;
      }
    });

    final target = _initialRecipient ?? (Get.arguments is AppUser ? Get.arguments as AppUser : null);
    if (target != null) {
      recipient.value = target;
      final myId = currentUid ?? '';
      chatId = ChatService.getChatId(myId, target.uid);
      _listenToMessages();
      markAsRead();
    } else {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    messageController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void toggleEmoji() {
    if (showEmoji.value) {
      showEmoji.value = false;
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
      showEmoji.value = true;
    }
  }

  void onEmojiSelected(String emoji) {
    final text = messageController.text;
    final selection = messageController.selection;
    final start = selection.start == -1 ? text.length : selection.start;
    final end = selection.end == -1 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, emoji);
    messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void onBackspace() {
    final text = messageController.text;
    if (text.isEmpty) return;
    final characters = text.characters;
    final newCharacters = characters.take(characters.length - 1);
    final newText = newCharacters.toString();
    messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _listenToMessages() {
    _messagesSub?.cancel();
    _messagesSub = _chatService.streamMessages(chatId).listen(
      (list) {
        messages.assignAll(list);
        isLoading.value = false;
        markAsRead();
        _scrollToBottom();
      },
      onError: (e) {
        log('streamMessages error: $e');
        isLoading.value = false;
        // Auto retry if stream failed before chat doc creation
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed) {
            _listenToMessages();
          }
        });
      },
    );
  }

  void markAsRead() {
    final myId = currentUid;
    if (myId != null && myId.isNotEmpty) {
      _chatService.markMessagesAsRead(chatId: chatId, currentUid: myId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final myId = currentUid;
    final other = recipient.value;
    if (myId == null || other == null) return;

    final myUser = currentUser;
    final myName = myUser?.displayName ?? (myUser?.email != null ? myUser!.email!.split('@').first : 'User');
    final myPhoto = myUser?.photoURL;
    final myEmail = myUser?.email;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Optimistically add message so it shows in the chat instantly
    final optimisticMsg = ChatMessage(
      id: tempId,
      senderId: myId,
      receiverId: other.uid,
      text: text,
      timestamp: now,
      isRead: false,
    );
    messages.add(optimisticMsg);
    isLoading.value = false;
    _scrollToBottom();

    messageController.clear();
    isSending.value = true;

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: myId,
        senderName: myName,
        senderPhoto: myPhoto,
        senderEmail: myEmail,
        recipient: other,
        text: text,
      );
      // Ensure real-time stream is active
      _listenToMessages();
      _scrollToBottom();
    } catch (e, stack) {
      log('sendMessage error: $e\n$stack');
      // Remove optimistic message if send failed
      messages.removeWhere((m) => m.id == tempId);
      messageController.text = text;
      showCustomToast('Failed to send message: $e');
    } finally {
      isSending.value = false;
    }
  }

  String formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('hh:mm a').format(dateTime.toLocal());
  }

  String formatDateHeader(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final local = dateTime.toLocal();

    final sameDay =
        now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;

    if (sameDay) return 'Today';

    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday =
        yesterday.year == local.year &&
        yesterday.month == local.month &&
        yesterday.day == local.day;

    if (wasYesterday) return 'Yesterday';

    return DateFormat('MMMM d, yyyy').format(local);
  }

  bool isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    final l1 = d1.toLocal();
    final l2 = d2.toLocal();
    return l1.year == l2.year && l1.month == l2.month && l1.day == l2.day;
  }
}
