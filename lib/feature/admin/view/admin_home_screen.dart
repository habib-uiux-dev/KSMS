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
            // The shop switch sits first because it is the thing an admin
            // opens this screen to change, morning and evening.
            const _OrderingToggleCard(),

            SizedBox(height: 18.h),

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

/// The open/closed switch for the whole shop.
class _OrderingToggleCard extends StatelessWidget {
  const _OrderingToggleCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();

    return Obx(() {
      final isOpen = controller.orderingOpen.value;
      final busy = controller.isTogglingOrdering.value;

      final accent = isOpen ? AdminColors.green : AdminColors.amber;
      final tint = isOpen ? const Color(0xFFDCFCE7) : AdminColors.amberBg;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(
              isOpen ? Icons.storefront : Icons.do_not_disturb_on_outlined,
              color: accent,
              size: 22.sp,
            ),

            SizedBox(width: 10.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOpen ? 'Orders are OPEN' : 'Orders are CLOSED',
                    style: GoogleFonts.openSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Text(
                    isOpen
                        ? 'Users can place and edit orders'
                        : 'Users see the contact-admin message',
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp,
                      color: AdminColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            if (busy)
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: isOpen,
                activeThumbColor: Colors.white,
                activeTrackColor: AdminColors.green,
                onChanged: (value) async {
                  // Only closing asks for confirmation. Opening is harmless;
                  // a stray tap that closes the shop blocks everyone at once.
                  if (!value) {
                    final confirmed = await _confirmClose(context);
                    if (confirmed != true) return;
                  }
                  await controller.setOrderingOpen(value);
                },
              ),
          ],
        ),
      );
    });
  }

  Future<bool?> _confirmClose(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Stop taking orders?',
        style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Nobody will be able to place or edit an order until you switch it '
        'back on.',
        style: GoogleFonts.openSans(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: GoogleFonts.openSans()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Close orders',
            style: GoogleFonts.openSans(color: AdminColors.amber),
          ),
        ),
      ],
    ),
  );
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PaymentBadge(collected: order.isCollected),
                SizedBox(width: 4.w),
                Obx(
                  () => IconButton(
                    onPressed: controller.isBusy(order.id)
                        ? null
                        : () => _confirmDelete(context, controller, order),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20.sp,
                      color: AdminColors.red,
                    ),
                    tooltip: 'Delete order',
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Editable only while the cash is still owed: once it is collected
          // the total has been paid against, and changing the lines would put
          // the takings and the order out of step.
          Obx(
            () => OrderItemsTable(
              order: order,
              isBusy: controller.isBusy(order.id),
              onQuantityChanged: order.isCollected
                  ? null
                  : (productId, delta) =>
                        controller.changeQuantity(order, productId, delta),
            ),
          ),

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

Future<void> _confirmDelete(
  BuildContext context,
  AdminDashboardController controller,
  ShopOrder order,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Delete this order?',
        style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Removing the order by ${order.userName} - ${order.itemCount} '
        'item${order.itemCount == 1 ? '' : 's'}, total ৳${order.total}. '
        'They can place a new one while the shop is open.',
        style: GoogleFonts.openSans(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: GoogleFonts.openSans()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Delete',
            style: GoogleFonts.openSans(color: AdminColors.red),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true) await controller.deleteOrder(order);
}
