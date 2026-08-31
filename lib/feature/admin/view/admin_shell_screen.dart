import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/image_loader.dart';
import '../../home/controller/home_controller.dart';
import '../controller/admin_controller.dart';
import 'admin_home_screen.dart';
import 'admin_notify_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_summary_screen.dart';
import 'widgets/admin_widgets.dart';

/// Holds the five admin tabs behind one bottom bar.
///
/// The tabs live in an IndexedStack, so switching keeps each tab's scroll
/// position and does not re-subscribe the Firestore listeners.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;

  static const _titles = ['Home', 'Orders', 'Summary', 'Products', 'Notify'];

  @override
  Widget build(BuildContext context) {
    final admin = Get.find<AdminController>();

    return Obx(() {
      // Access revoked from the console while the screen is open - do not sit
      // on data this user is no longer allowed to see.
      if (!admin.isAdmin.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute.contains('admin')) Get.back();
        });
      }

      return Scaffold(
        backgroundColor: AdminColors.bg,
        appBar: AppBar(
          backgroundColor: AdminColors.bg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: AdminColors.ink),
            tooltip: 'Back to shop',
          ),
          title: Text(
            'Joldi Order Dao',
            style: GoogleFonts.openSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AdminColors.green,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: _AdminAvatar(),
            ),
          ],
        ),

        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: const [
              AdminHomeScreen(),
              AdminOrdersScreen(),
              AdminSummaryScreen(),
              AdminProductsScreen(),
              AdminNotifyScreen(),
            ],
          ),
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF3ECF6B),
          height: 68.h,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (var i = 0; i < _titles.length; i++)
              NavigationDestination(
                icon: Icon(_iconFor(i), color: AdminColors.ink),
                selectedIcon: Icon(_iconFor(i), color: Colors.white),
                label: _titles[i],
              ),
          ],
        ),
      );
    });
  }

  IconData _iconFor(int index) => switch (index) {
    0 => Icons.dashboard_outlined,
    1 => Icons.receipt_long_outlined,
    2 => Icons.bar_chart_outlined,
    3 => Icons.inventory_2_outlined,
    _ => Icons.campaign_outlined,
  };
}

class _AdminAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Obx(() {
      final url = home.avatarUrl;
      return CircleAvatar(
        radius: 18.r,
        backgroundColor: AdminColors.tile,
        child: ClipOval(
          child: url != null && url.isNotEmpty
              ? ImageLoader(url: url, size: 36.sp, boxFit: BoxFit.cover)
              : Icon(Icons.person, color: AdminColors.green, size: 20.sp),
        ),
      );
    });
  }
}
