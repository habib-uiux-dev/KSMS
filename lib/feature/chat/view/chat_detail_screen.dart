import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/image_loader.dart';
import '../controller/chat_detail_controller.dart';
import '../model/chat_message.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key});

  static const Color _primaryGreen = Color(0xFF1E8C3A);
  static const Color _chatBgColor = Color(0xFFEFEAE2);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatDetailController>();

    return Obx(() {
      return PopScope(
        canPop: !controller.showEmoji.value,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && controller.showEmoji.value) {
            controller.showEmoji.value = false;
          }
        },
        child: Scaffold(
          backgroundColor: _chatBgColor,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: _primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
          tooltip: 'Back',
        ),
        titleSpacing: 0,
        title: Obx(() {
          final user = controller.recipient.value;
          final photo = user?.photoUrl;
          final name = (user?.name != null && user!.name!.trim().isNotEmpty)
              ? user.name!.trim()
              : (user?.email ?? 'Chat');
          final sub = user?.designation ?? user?.email ?? '';

          return Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: (photo != null && photo.isNotEmpty)
                      ? ImageLoader(
                          url: photo,
                          size: 36.r,
                          boxFit: BoxFit.cover,
                        )
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.openSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          fontSize: 11.sp,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
            ],
          );
        }),

      ),
      body: SafeArea(
        child: Column(
          children: [
            // ================= MESSAGES LIST =================
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  );
                }

                final messages = controller.messages;
                if (messages.isEmpty) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Say hello! Tap below to start chatting.',
                        style: GoogleFonts.openSans(
                          fontSize: 13.sp,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 12.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == controller.currentUid;

                    final showDateHeader = index == 0 ||
                        !controller.isSameDay(
                          messages[index - 1].timestamp,
                          message.timestamp,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateHeader)
                          _DateHeaderBadge(
                            dateText: controller.formatDateHeader(
                              message.timestamp,
                            ),
                          ),
                        _MessageBubble(
                          message: message,
                          isMe: isMe,
                          timeText: controller.formatMessageTime(
                            message.timestamp,
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
            ),

            // ================= WHATSAPP INPUT BAR =================
            _WhatsAppInputBar(
              controller: controller.messageController,
              focusNode: controller.focusNode,
              showEmoji: controller.showEmoji.value,
              onToggleEmoji: controller.toggleEmoji,
              onSend: controller.sendMessage,
            ),

            // ================= EMOJI PICKER =================
            if (controller.showEmoji.value)
              _WhatsAppEmojiPicker(
                onEmojiSelected: controller.onEmojiSelected,
                onBackspace: controller.onBackspace,
              ),
          ],
        ),
      ),
    ),
  );
});
  }
}

class _DateHeaderBadge extends StatelessWidget {
  const _DateHeaderBadge({required this.dateText});

  final String dateText;

  @override
  Widget build(BuildContext context) {
    if (dateText.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE1DCD5),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
        child: Text(
          dateText,
          style: GoogleFonts.openSans(
            fontSize: 11.sp,
            color: const Color(0xFF555555),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.timeText,
  });

  final ChatMessage message;
  final bool isMe;
  final String timeText;

  static const Color _primaryGreen = Color(0xFF1E8C3A);
  static const Color _readTickColor = Color(0xFF53BDEB);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60.w : 4.w,
          right: isMe ? 4.w : 60.w,
          top: 3.h,
          bottom: 3.h,
        ),
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 6.h),
        decoration: BoxDecoration(
          color: isMe ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14.r),
            topRight: Radius.circular(14.r),
            bottomLeft: isMe ? Radius.circular(14.r) : Radius.circular(2.r),
            bottomRight: isMe ? Radius.circular(2.r) : Radius.circular(14.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: GoogleFonts.openSans(
                fontSize: 14.5.sp,
                color: isMe ? Colors.white : const Color(0xFF14161A),
                height: 1.3,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeText,
                  style: GoogleFonts.openSans(
                    fontSize: 10.5.sp,
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done_all,
                    size: 14.sp,
                    color: message.isRead ? _readTickColor : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppInputBar extends StatelessWidget {
  const _WhatsAppInputBar({
    required this.controller,
    required this.focusNode,
    required this.showEmoji,
    required this.onToggleEmoji,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmoji;
  final VoidCallback onToggleEmoji;
  final VoidCallback onSend;

  static const Color _primaryGreen = Color(0xFF1E8C3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text Input Pill
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Emoji / Keyboard Toggle Button
                  IconButton(
                    splashRadius: 20.r,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 42.w,
                      minHeight: 44.h,
                    ),
                    icon: Icon(
                      showEmoji
                          ? Icons.keyboard_alt_outlined
                          : Icons.emoji_emotions_outlined,
                      color: Colors.grey.shade600,
                      size: 24.sp,
                    ),
                    onPressed: onToggleEmoji,
                    tooltip: showEmoji ? 'Keyboard' : 'Emoji',
                  ),

                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      style: GoogleFonts.openSans(
                        fontSize: 15.sp,
                        color: const Color(0xFF14161A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: GoogleFonts.openSans(
                          fontSize: 15.sp,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
            ),
          ),

          SizedBox(width: 6.w),

          // Send Button
          Material(
            color: _primaryGreen,
            shape: const CircleBorder(),
            elevation: 1.5,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: SizedBox(
                width: 44.r,
                height: 44.r,
                child: Center(
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 19.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// WhatsApp-style Categorized Emoji Picker Widget.
class _WhatsAppEmojiPicker extends StatefulWidget {
  const _WhatsAppEmojiPicker({
    required this.onEmojiSelected,
    required this.onBackspace,
  });

  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onBackspace;

  @override
  State<_WhatsAppEmojiPicker> createState() => _WhatsAppEmojiPickerState();
}

class _WhatsAppEmojiPickerState extends State<_WhatsAppEmojiPicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<_EmojiCategory> _categories = [
    _EmojiCategory(
      icon: Icons.sentiment_satisfied_alt_outlined,
      tooltip: 'Smileys & People',
      emojis: [
        '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
        '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
        '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸',
        '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
        '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡',
        '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓',
        '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄',
        '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵',
        '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠',
      ],
    ),
    _EmojiCategory(
      icon: Icons.pan_tool_outlined,
      tooltip: 'Gestures',
      emojis: [
        '👍', '👎', '👌', '🤌', '🤏', '✌️', '🤞', '🫰', '🤟', '🤘',
        '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '🫵', '👋', '🤚',
        '🖐️', '✋', '🖖', '🫱', '🫲', '🫳', '🫴', '🤝', '👏', '🙌',
        '🫶', '👐', '🤲', '🙏', '✍️', '💅', '🤳', '💪', '🦾', '🦿',
        '🦵', '🦶', '👂', '🦻', '👃', '🧠', '🫀', '🫁', '🦷', '🦴',
        '👀', '👁️', '👅', '👄', '🫦',
      ],
    ),
    _EmojiCategory(
      icon: Icons.favorite_border,
      tooltip: 'Hearts & Emotions',
      emojis: [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
        '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
        '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️',
        '☦️', '🛐', '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎',
        '♏', '♐', '♑', '♒', '♓', '💯', '💢', '💥', '💫', '💦',
        '💨', '🕳️', '💣', '💬', '👁️‍🗨️', '🗨️', '🗯️', '💭', '💤',
      ],
    ),
    _EmojiCategory(
      icon: Icons.pets_outlined,
      tooltip: 'Animals & Nature',
      emojis: [
        '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
        '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆',
        '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🪱', '🐛',
        '🦋', '🐌', '🐞', '🐜', '🪰', '🪲', '🪳', '🪴', '🌲', '🌳',
        '🌴', '🌵', '🌾', '🌿', '☘️', '🍀', '🍁', '🍂', '🍃', '🍄',
        '🌹', '🌺', '🌻', '🌼', '🌷', '🌸', '💐', '🌙', '⭐', '🌟',
      ],
    ),
    _EmojiCategory(
      icon: Icons.fastfood_outlined,
      tooltip: 'Food & Drink',
      emojis: [
        '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐',
        '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑',
        '🥦', '🥬', '🥒', '🌶️', '🫑', '🌽', '🥕', '🫒', '🧄', '🧅',
        '🥔', '🍠', '🥐', '🥯', '🍞', '🥖', '🥨', '🧀', '🥚', '🍳',
        '🧈', '🥞', '🧇', '🥓', '🥩', '🍗', '🍖', '🌭', '🍔', '🍟',
        '🍕', '🥪', '🥙', '🧆', '🌮', '🌯', '🥗', '🥘', '🥫', '🍝',
        '🍜', '🍲', '🍛', '🍣', '🍱', '🥟', '🍤', '🍚', '🍦', '🍧',
        '🎂', '🍰', '🧁', '🥧', '🍫', '🍬', '🍭', '🍮', '🍯', '☕',
      ],
    ),
    _EmojiCategory(
      icon: Icons.sports_soccer_outlined,
      tooltip: 'Sports & Activities',
      emojis: [
        '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
        '🪀', '🏓', '🏸', '🏒', '🏏', '⛳', '🎯', '🤿', '🥊', '🥋',
        '🛹', '🛼', '⛸️', '🎿', '🏋️', '🤸', '🧗', '🧘', '🏄', '🏊',
        '🚴', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖️', '🎫', '🎪', '🎨',
        '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸', '🎮',
        '🚗', '🚕', '🚙', '🚌', '🏎️', '🚓', '🚑', '🚒', '🚚', '✈️',
        '🚀', '🛸', '🚁', '🚲', '🛵', '🏍️',
      ],
    ),
    _EmojiCategory(
      icon: Icons.celebration_outlined,
      tooltip: 'Objects & Flags',
      emojis: [
        '🎉', '🎊', '🎈', '🎁', '🎂', '🪄', '🎃', '🎄', '🎆', '🎇',
        '✨', '🎋', '🎀', '🔮', '📱', '📲', '💻', '⌨️', '🖥️', '🖨️',
        '📷', '🔍', '💡', '🔦', '📖', '📚', '💰', '💵', '💳', '✉️',
        '📦', '✏️', '✒️', '📝', '🔒', '🔓', '🔑', '🔨', '🛠️', '⚙️',
        '🧲', '🧪', '🧬', '💉', '💊', '🛒', '🇧🇩', '🇺🇸', '🇬🇧', '🇨🇦',
        '🇦🇺', '🇯🇵', '🇩🇪', '🇫🇷', '🇮🇳', '🇵🇰', '🇸🇦', '🇦🇪', '🇹🇷',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270.h,
      color: const Color(0xFFF0F2F5),
      child: Column(
        children: [
          // Emoji Grid Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: cat.emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = cat.emojis[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () => widget.onEmojiSelected(emoji),
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: 24.sp),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),

          // Bottom Category Selector & Backspace
          Container(
            height: 44.h,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: const Color(0xFF1E8C3A),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF1E8C3A),
                    unselectedLabelColor: Colors.grey.shade600,
                    labelPadding: EdgeInsets.zero,
                    tabs: _categories.map((cat) {
                      return Tab(
                        icon: Icon(cat.icon, size: 22.sp),
                      );
                    }).toList(),
                  ),
                ),
                // Backspace Button
                IconButton(
                  splashRadius: 20.r,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: Colors.grey.shade700,
                    size: 21.sp,
                  ),
                  onPressed: widget.onBackspace,
                  tooltip: 'Backspace',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiCategory {
  const _EmojiCategory({
    required this.icon,
    required this.tooltip,
    required this.emojis,
  });

  final IconData icon;
  final String tooltip;
  final List<String> emojis;
}
