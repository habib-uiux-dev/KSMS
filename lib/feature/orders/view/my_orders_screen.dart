import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../home/model/order.dart';
import '../controller/orders_controller.dart';

const Color _green = Color(0xFF116A2A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF6E7A74);
const Color _line = Color(0xFFE8ECE9);
const Color _cancelled = Color(0xFFC62828);

/// The caller's own order history, newest first, grouped by day.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();

    return Obx(() {
      if (controller.isLoadingMine.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final orders = controller.myOrders;
      if (orders.isEmpty) {
        return _Empty();
      }

      return ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final previous = index == 0 ? null : orders[index - 1];

          // One heading per day rather than one per card: consecutive orders
          // from the same day sit under a single label.
          final showHeading =
              previous == null || previous.orderDate != order.orderDate;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeading) ...[
                SizedBox(height: index == 0 ? 8.h : 20.h),
                Text(
                  _dayLabel(order.orderDate),
                  style: GoogleFonts.openSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 10.h),
              ] else
                SizedBox(height: 12.h),
              _OrderCard(order: order),
            ],
          );
        },
      );
    });
  }
}

/// "Today" / "Yesterday" for the two days people actually recognise, a date
/// for everything older.
String _dayLabel(int dateKey) {
  final today = ShopOrder.todayKey();
  if (dateKey == today) return 'Today';

  final yesterday = ShopOrder.dateKeyOf(
    DateTime.now().subtract(const Duration(days: 1)),
  );
  if (dateKey == yesterday) return 'Yesterday';

  final year = dateKey ~/ 10000;
  final month = (dateKey ~/ 100) % 100;
  final day = dateKey % 100;
  return DateFormat('d MMMM, yyyy').format(DateTime(year, month, day));
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final placedAt = order.createdAt;
    final cancelled = order.isCancelled;

    // Greyed rather than hidden. This card is the record of what happened, and
    // a history that quietly omits the cancelled day is how someone ends up
    // asking the shop keeper why they were charged for nothing.
    final bodyColor = cancelled ? _muted : _ink;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cancelled ? const Color(0xFFF6F7F6) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: cancelled
            ? Border.all(color: _cancelled.withValues(alpha: 0.25))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (cancelled)
                _CancelledBadge()
              else
                Text(
                  order.isCollected ? 'Paid' : 'Order Placed',
                  style: GoogleFonts.openSans(fontSize: 13.sp, color: _muted),
                ),
              const Spacer(),
              Text(
                placedAt == null ? '' : DateFormat('h:mm a').format(placedAt),
                style: GoogleFonts.openSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: bodyColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(height: 1, color: _line),
          SizedBox(height: 10.h),

          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 14.sp,
                        color: bodyColor,
                        decoration: cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    '৳${item.lineTotal}',
                    style: GoogleFonts.openSans(
                      fontSize: 14.sp,
                      color: bodyColor,
                      decoration: cancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 6.h),
          Divider(height: 1, color: _line),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                'Total',
                style: GoogleFonts.openSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: bodyColor,
                ),
              ),
              const Spacer(),
              Text(
                '৳${order.total}',
                style: GoogleFonts.openSans(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: cancelled ? _muted : _green,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),

          if (cancelled) ...[
            SizedBox(height: 10.h),
            Text(
              _cancelLine(order),
              style: GoogleFonts.openSans(fontSize: 12.sp, color: _cancelled),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Cancelled at 2:14 PM · স্টক শেষ", or just the time when no reason was left.
String _cancelLine(ShopOrder order) {
  final at = order.cancelledAt;
  final when = at == null ? '' : ' at ${DateFormat('h:mm a').format(at)}';
  final reason = order.cancelReason;
  return reason.isEmpty
      ? 'Cancelled by the shop$when'
      : 'Cancelled by the shop$when · $reason';
}

class _CancelledBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _cancelled.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        'Cancelled',
        style: GoogleFonts.openSans(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: _cancelled,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48.sp, color: _muted),
          SizedBox(height: 12.h),
          Text(
            'No orders yet',
            style: GoogleFonts.openSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your orders will show up here.',
            style: GoogleFonts.openSans(fontSize: 13.sp, color: _muted),
          ),
        ],
      ),
    );
  }
}
