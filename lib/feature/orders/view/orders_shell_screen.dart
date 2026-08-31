import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../controller/orders_controller.dart';
import 'leaderboard_screen.dart';
import 'my_orders_screen.dart';

const Color _green = Color(0xFF16A34A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF6E7A74);

/// Holds the two history tabs. Both read the same controller, so switching
/// between them never re-queries.
class OrdersShellScreen extends StatelessWidget {
  const OrdersShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'History',
        bgColor: const Color(0xFFF7F8FA),
        textStyle: GoogleFonts.openSans(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
      body: Obx(
        () => IndexedStack(
          index: controller.tabIndex.value,
          children: const [MyOrdersScreen(), LeaderboardScreen()],
        ),
      ),
      bottomNavigationBar: Obx(
        () => _BottomBar(
          index: controller.tabIndex.value,
          onChanged: (i) => controller.tabIndex.value = i,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            Expanded(
              child: _Item(
                icon: Icons.receipt_long_outlined,
                label: 'My Orders',
                isSelected: index == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _Item(
                icon: Icons.leaderboard_outlined,
                label: 'Leaderboard',
                isSelected: index == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? _green : Colors.transparent,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected ? Colors.white : _muted,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.openSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
