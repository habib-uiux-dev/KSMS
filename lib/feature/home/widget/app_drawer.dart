import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/widgets/image_loader.dart';
import '../../admin/controller/admin_controller.dart';
import '../controller/home_controller.dart';
import 'edit_profile_sheet.dart';

const Color _green = Color(0xFF1E8C3A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF6E7A74);
const Color _line = Color(0xFFE8ECE9);

/// The app's one navigation surface.
///
/// The header used to carry an admin button and a sign-out button side by side,
/// which left no room for anything else and put a destructive action one
/// mis-tap away from the avatar. Everything lives here now, behind one menu.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.onAdminTap,
    required this.onSignOutTap,
  });

  /// Home owns these because they raise dialogs that need its context and its
  /// wording; the drawer only decides where they sit.
  final VoidCallback onAdminTap;
  final VoidCallback onSignOutTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(controller: controller),
          Divider(height: 1, color: _line),
          SizedBox(height: 8.h),

          _Tile(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed(Routes.myOrders);
            },
          ),
          _Tile(
            icon: Icons.leaderboard_outlined,
            label: 'Leaderboard',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed(Routes.myOrders, arguments: {'tab': 1});
            },
          ),

          // Shown to everyone, and identical either way: a button that
          // appeared only for admins would advertise who they are.
          Obx(() {
            final admin = Get.find<AdminController>();
            return _Tile(
              icon: admin.isAdmin.value
                  ? Icons.admin_panel_settings
                  : Icons.admin_panel_settings_outlined,
              label: 'Admin Panel',
              onTap: () {
                Navigator.pop(context);
                onAdminTap();
              },
            );
          }),

          const Spacer(),
          Divider(height: 1, color: _line),
          _Tile(
            icon: Icons.logout,
            label: 'Log Out',
            color: const Color(0xFFEF4C4C),
            onTap: () {
              Navigator.pop(context);
              onSignOutTap();
            },
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final HomeController controller;

  /// Closes the drawer first, then opens the sheet.
  ///
  /// Stacking a modal sheet on top of an open drawer leaves two dismiss
  /// gestures fighting each other. `Get.context` is the navigator's own
  /// context, so it outlives the drawer being popped here.
  void _openEditor(BuildContext context) {
    Navigator.pop(context);
    final navigatorContext = Get.context;
    if (navigatorContext != null) showEditProfileSheet(navigatorContext);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _green,
      child: InkWell(
        onTap: () => _openEditor(context),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 20.h),
          child: Obx(() {
            final url = controller.avatarUrl;
            final designation = controller.greetingDesignation;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: Colors.white24,
                  child: ClipOval(
                    child: url != null && url.isNotEmpty
                        ? ImageLoader(
                            url: url,
                            size: 60.sp,
                            boxFit: BoxFit.cover,
                          )
                        : Icon(Icons.person, size: 32.sp, color: Colors.white),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.greetingName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.openSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (designation.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              designation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                fontSize: 13.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // A whole tappable header with no affordance reads as
                    // decoration, so the pencil says it is editable.
                    Icon(
                      Icons.edit_outlined,
                      size: 18.sp,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? _ink;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22.sp, color: color ?? _muted),
      title: Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: tint,
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
