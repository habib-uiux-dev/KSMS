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
    final cancelled = order.isCancelled;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        // Still on screen, visibly struck out. An admin who cancels an order
        // needs to see that they did - a card that disappeared was how the
        // old delete button lost the shop its own history.
        color: cancelled ? const Color(0xFFF6F7F6) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: cancelled
              ? AdminColors.red.withValues(alpha: 0.3)
              : AdminColors.line,
        ),
      ),
      child: Column(
        children: [
          OrderPersonRow(
            order: order,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cancelled)
                  _CancelledChip()
                else ...[
                  PaymentBadge(collected: order.isCollected),
                  SizedBox(width: 4.w),
                  Obx(
                    () => IconButton(
                      onPressed: controller.isBusy(order.id)
                          ? null
                          : () => _confirmCancel(context, controller, order),
                      icon: Icon(
                        Icons.cancel_outlined,
                        size: 20.sp,
                        color: AdminColors.red,
                      ),
                      tooltip: 'Cancel order',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Editable only while the cash is still owed: once it is collected
          // the total has been paid against, and changing the lines would put
          // the takings and the order out of step. A cancelled order is not
          // editable at all - there is nothing left to correct.
          Obx(
            () => OrderItemsTable(
              order: order,
              isBusy: controller.isBusy(order.id),
              onQuantityChanged: order.isCollected || cancelled
                  ? null
                  : (productId, delta) =>
                        controller.changeQuantity(order, productId, delta),
            ),
          ),

          SizedBox(height: 12.h),

          Obx(() {
            final busy = controller.isBusy(order.id);

            if (cancelled) {
              // No action button: the user re-orders from their own phone,
              // which is also the only path the security rules allow.
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  order.cancelReason.isEmpty
                      ? 'Cancelled · they can order again'
                      : 'Cancelled · ${order.cancelReason}',
                  style: GoogleFonts.openSans(
                    fontSize: 12.sp,
                    color: AdminColors.red,
                  ),
                ),
              );
            }

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

/// Small chip in place of the payment badge once an order is struck out.
class _CancelledChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AdminColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        'Cancelled',
        style: GoogleFonts.openSans(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AdminColors.red,
        ),
      ),
    );
  }
}

/// Asks which reason, not whether.
///
/// The reason is not optional garnish: it is the sentence the person who
/// ordered will read on their home screen. "Your order was cancelled" with no
/// explanation is worse than the old silent delete, because it says something
/// happened and refuses to say what.
Future<void> _confirmCancel(
  BuildContext context,
  AdminDashboardController controller,
  ShopOrder order,
) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(
        'Cancel ${order.userName}’s order?',
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.w700,
          fontSize: 17.sp,
        ),
      ),
      contentPadding: EdgeInsets.only(bottom: 8.h),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
          child: Text(
            '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}, '
            '৳${order.total}. They will see the reason on their home screen '
            'and can order again.',
            style: GoogleFonts.openSans(
              fontSize: 13.sp,
              color: AdminColors.muted,
            ),
          ),
        ),
        for (final option in AdminDashboardController.cancelReasons)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, option),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(Icons.arrow_right, size: 18.sp, color: AdminColors.muted),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.openSans(
                      fontSize: 15.sp,
                      color: AdminColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.only(right: 12.w, top: 4.h),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep the order', style: GoogleFonts.openSans()),
            ),
          ),
        ),
      ],
    ),
  );

  if (reason != null) await controller.cancelOrder(order, reason);
}
