import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/model/order.dart';
import '../controller/admin_dashboard_controller.dart';
import 'widgets/admin_widgets.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value != null && controller.orders.isEmpty) {
        return AdminEmpty(
          message: controller.errorMessage.value!,
          icon: Icons.error_outline,
        );
      }

      return RefreshIndicator(
        onRefresh: () async => controller.refreshOrders(),
        color: AdminColors.green,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Text(
              "Today's Orders",
              style: GoogleFonts.openSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: AdminColors.ink,
              ),
            ),

            SizedBox(height: 14.h),

            // ================= STAT GRID =================
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 1.7,
              children: [
                StatCard(
                  label: 'Total orders',
                  value: '${controller.totalOrders}',
                  icon: Icons.grid_view_rounded,
                ),
                StatCard(
                  label: 'Total amount',
                  value: '৳${controller.totalAmount}',
                  icon: Icons.account_balance_wallet_outlined,
                  valueColor: AdminColors.green,
                ),
                StatCard(
                  label: 'Collected',
                  value: '৳${controller.collectedAmount}',
                  icon: Icons.check_circle_outline,
                  valueColor: AdminColors.green,
                  iconBg: const Color(0xFFDCFCE7),
                ),
                StatCard(
                  label: 'Pending',
                  value: '৳${controller.pendingAmount}',
                  icon: Icons.more_horiz,
                  valueColor: AdminColors.amber,
                  iconBg: AdminColors.amberBg,
                ),
              ],
            ),

            SizedBox(height: 22.h),

            Text(
              "Today's Orders",
              style: GoogleFonts.openSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AdminColors.ink,
              ),
            ),

            SizedBox(height: 10.h),

            if (controller.orders.isEmpty)
              const AdminEmpty(
                message: 'No orders yet today',
                icon: Icons.receipt_long_outlined,
              )
            else
              for (final order in controller.orders)
                _AdminOrderCard(order: order),
          ],
        ),
      );
    });
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();

    return Container(
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
            trailing: PaymentBadge(collected: order.isCollected),
          ),

          SizedBox(height: 12.h),

          OrderItemsTable(order: order),

          SizedBox(height: 12.h),

          Obx(() {
            final busy = controller.isBusy(order.id);

            if (order.isCollected) {
              // Already paid: offer the undo instead of a dead button, since a
              // mis-tap on a cash screen needs a way back.
              return SizedBox(
                width: double.infinity,
                height: 46.h,
                child: TextButton(
                  onPressed: busy ? null : () => controller.markPending(order),
                  style: TextButton.styleFrom(
                    backgroundColor: AdminColors.tile,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    busy ? 'Updating...' : 'Undo collection',
                    style: GoogleFonts.openSans(
                      fontWeight: FontWeight.w700,
                      color: AdminColors.ink,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: busy ? null : () => controller.markCollected(order),
                icon: busy
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.check, size: 18.sp, color: Colors.white),
                label: Text(
                  busy ? 'Saving...' : 'Mark Collected',
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
              ),
            );
          }),
        ],
      ),
    );
  }
}
