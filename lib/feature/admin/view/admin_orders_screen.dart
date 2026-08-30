import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/admin_dashboard_controller.dart';
import 'widgets/admin_widgets.dart';

/// Cash Collection: who still owes money today, and a button to settle it.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final pending = controller.pendingOrders;

      return RefreshIndicator(
        onRefresh: () async => controller.refreshOrders(),
        color: AdminColors.green,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: AdminColors.green),
                SizedBox(width: 8.w),
                Text(
                  'Cash Collection',
                  style: GoogleFonts.openSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.ink,
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // ================= TOTAL TO COLLECT =================
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AdminColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total to Collect',
                    style: GoogleFonts.openSans(color: AdminColors.muted),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '৳${controller.totalAmount}',
                    style: GoogleFonts.openSans(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: _MoneyTile(
                    label: 'Collected',
                    amount: controller.collectedAmount,
                    color: AdminColors.green,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _MoneyTile(
                    label: 'Pending',
                    amount: controller.pendingAmount,
                    color: AdminColors.amber,
                    icon: Icons.schedule,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            Text(
              'Pending Payments',
              style: GoogleFonts.openSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AdminColors.ink,
              ),
            ),

            SizedBox(height: 10.h),

            if (pending.isEmpty)
              const AdminEmpty(
                message: 'Everything is collected',
                icon: Icons.verified_outlined,
              )
            else
              for (final order in pending)
                Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AdminColors.line),
                  ),
                  child: Column(
                    children: [
                      OrderPersonRow(
                        order: order,
                        trailing: Obx(() {
                          final busy = controller.isBusy(order.id);
                          return ElevatedButton.icon(
                            onPressed: busy
                                ? null
                                : () => controller.markCollected(order),
                            icon: busy
                                ? SizedBox(
                                    width: 14.w,
                                    height: 14.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.payments_outlined,
                                    size: 16.sp,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              'Collect',
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.green,
                              disabledBackgroundColor: const Color(0xFF86C8A2),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: 12.h),

                      OrderItemsTable(order: order),
                    ],
                  ),
                ),
          ],
        ),
      );
    });
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AdminColors.line),
        // The coloured underline is what separates the two tiles at a glance.
        boxShadow: [BoxShadow(color: color, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.sp, color: color),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(color: AdminColors.muted),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '৳$amount',
              style: GoogleFonts.openSans(
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
