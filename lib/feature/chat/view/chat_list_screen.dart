import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/utils/user_filter.dart';
import '../../../core/widgets/image_loader.dart';
import '../../auth/model/app_user.dart';
import '../controller/chat_list_controller.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  static const Color _primaryGreen = Color(0xFF1E8C3A);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatListController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Chats',
          style: GoogleFonts.openSans(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ================= SEARCH BAR =================
          Container(
            color: _primaryGreen,
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                style: GoogleFonts.openSans(
                  fontSize: 14.sp,
                  color: const Color(0xFF14161A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: GoogleFonts.openSans(
                    fontSize: 14.sp,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20.sp,
                  ),
                  suffixIcon: Obx(() {
                    if (controller.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 18.sp,
                      ),
                      onPressed: controller.clearSearch,
                    );
                  }),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 11.h,
                  ),
                ),
              ),
            ),
          ),

          // ================= USERS / CHATS LIST =================
          Expanded(
            child: Obx(() {
              if (controller.isLoadingUsers.value &&
                  controller.users.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: _primaryGreen),
                );
              }

              final filtered = controller.filteredUsers;
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64.sp,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        controller.searchQuery.value.isEmpty
                            ? 'No users found'
                            : 'No matching users',
                        style: GoogleFonts.openSans(
                          fontSize: 16.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.8,
                  indent: 82.w,
                  endIndent: 16.w,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  final chat = controller.getChatForUser(user.uid);
                  return _WhatsAppChatTile(
                    user: user,
                    chatLastMessage: chat?.lastMessage,
                    lastMessageSenderId: chat?.lastMessageSenderId,
                    lastMessageTime:
                        chat?.lastMessageTime ?? chat?.updatedAt,
                    unreadCount: chat?.getUnreadCount(
                          controller.currentUid ?? '',
                        ) ??
                        0,
                    currentUid: controller.currentUid ?? '',
                    formatTime: controller.formatTimestamp,
                    onTap: () {
                      Get.toNamed(Routes.chatDetail, arguments: user);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppChatTile extends StatelessWidget {
  const _WhatsAppChatTile({
    required this.user,
    required this.chatLastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.currentUid,
    required this.formatTime,
    required this.onTap,
  });

  final AppUser user;
  final String? chatLastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String currentUid;
  final String Function(DateTime?) formatTime;
  final VoidCallback onTap;

  static const Color _primaryGreen = Color(0xFF1E8C3A);

  @override
  Widget build(BuildContext context) {
    if (UserFilter.isExcluded(
      uid: user.uid,
      name: user.name,
      email: user.email,
    )) {
      return const SizedBox.shrink();
    }

    final hasMessage = chatLastMessage != null && chatLastMessage!.isNotEmpty;
    final isMe = hasMessage && lastMessageSenderId == currentUid;
    final timeStr = formatTime(lastMessageTime);

    final displayName = (user.name != null && user.name!.trim().isNotEmpty)
        ? user.name!.trim()
        : (user.email ?? 'Colleague');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // User Avatar (WhatsApp style)
            CircleAvatar(
              radius: 26.r,
              backgroundColor: const Color(0xFFE8F5E9),
              child: ClipOval(
                child: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? ImageLoader(
                        url: user.photoUrl!,
                        size: 52.r,
                        boxFit: BoxFit.cover,
                      )
                    : Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.openSans(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryGreen,
                        ),
                      ),
              ),
            ),

            SizedBox(width: 14.w),

            // Middle Content: Name, Email & Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            fontSize: 16.sp,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: const Color(0xFF14161A),
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: GoogleFonts.openSans(
                            fontSize: 12.sp,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: unreadCount > 0
                                ? _primaryGreen
                                : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),

                  if (hasMessage) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        if (isMe) ...[
                          Icon(
                            Icons.done_all,
                            size: 15.sp,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 4.w),
                        ],
                        Expanded(
                          child: Text(
                            chatLastMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.openSans(
                              fontSize: 13.5.sp,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: unreadCount > 0
                                  ? const Color(0xFF14161A)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: EdgeInsets.only(left: 6.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: const BoxDecoration(
                              color: _primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: GoogleFonts.openSans(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
