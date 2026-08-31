import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../home/model/order.dart';

/// Colours shared by every admin screen, in one place so the five tabs cannot
/// drift apart.
class AdminColors {
  AdminColors._();

  static const bg = Color(0xFFF7F8FA);
  static const green = Color(0xFF116A2A);
  static const greenLight = Color(0xFF1E8C3A);
  static const amber = Color(0xFFB45309);
  static const amberBg = Color(0xFFFEF3C7);
  static const tile = Color(0xFFEFF3FF);
  static const ink = Color(0xFF0F2540);
  static const muted = Color(0xFF6E7A74);
  static const line = Color(0xFFE6E9EF);

  /// Destructive actions - delete, and nothing else.
  static const red = Color(0xFFEF4C4C);
}

/// One of the four numbers at the top of the admin home screen.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.iconBg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Color? iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 11.sp,
                    letterSpacing: 0.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.muted,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: iconBg ?? AdminColors.tile,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 14.sp,
                  color: valueColor ?? AdminColors.green,
                ),
              ),
            ],
          ),
          //const SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.openSans(
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AdminColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tinted lines-and-total block inside an order card.
class OrderItemsTable extends StatelessWidget {
  const OrderItemsTable({
    super.key,
    required this.order,
    this.onQuantityChanged,
    this.isBusy = false,
  });

  final ShopOrder order;

  /// When supplied, each line gains -/+ controls. Left null on read-only
  /// surfaces (the summary tab), so the same table serves both.
  final void Function(String productId, int delta)? onQuantityChanged;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminColors.tile,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          for (final item in order.items)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(color: AdminColors.ink),
                    ),
                  ),
                  if (onQuantityChanged == null)
                    Text(
                      '৳${item.price} × ${item.quantity}',
                      style: GoogleFonts.openSans(color: AdminColors.muted),
                    )
                  else ...[
                    _StepButton(
                      icon: Icons.remove,
                      onTap: isBusy
                          ? null
                          : () => onQuantityChanged!(item.productId, -1),
                    ),
                    SizedBox(
                      width: 34.w,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w700,
                          color: AdminColors.ink,
                        ),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add,
                      onTap: isBusy
                          ? null
                          : () => onQuantityChanged!(item.productId, 1),
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 46.w,
                      child: Text(
                        '৳${item.lineTotal}',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.openSans(color: AdminColors.muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          Divider(height: 14.h, color: Color(0xFFD7DEEE)),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink,
                  ),
                ),
              ),
              Text(
                '৳${order.total}',
                style: GoogleFonts.openSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar + name + designation, used by every order card.
class OrderPersonRow extends StatelessWidget {
  const OrderPersonRow({super.key, required this.order, this.trailing});

  final ShopOrder order;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: AdminColors.tile,
          child: Icon(Icons.person, color: AdminColors.green),
        ),

        SizedBox(width: 10.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.userName.isEmpty ? 'Unknown' : order.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.openSans(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.ink,
                ),
              ),
              if (order.userDesignation.isNotEmpty)
                Text(
                  order.userDesignation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 13.sp,
                    color: AdminColors.muted,
                  ),
                ),
            ],
          ),
        ),

        ?trailing,
      ],
    );
  }
}

/// PAYMENT PENDING / COLLECTED pill.
class PaymentBadge extends StatelessWidget {
  const PaymentBadge({super.key, required this.collected});

  final bool collected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: collected ? const Color(0xFFDCFCE7) : AdminColors.amberBg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            collected ? Icons.done_all : Icons.circle,
            size: collected ? 14 : 8,
            color: collected ? AdminColors.green : AdminColors.amber,
          ),
          SizedBox(width: 6.w),
          Text(
            collected ? 'COLLECTED' : 'PAYMENT PENDING',
            style: GoogleFonts.openSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: collected ? AdminColors.green : AdminColors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared empty / error placeholder for the admin tabs.
class AdminEmpty extends StatelessWidget {
  const AdminEmpty({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 44.sp,
              color: AdminColors.muted,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(color: AdminColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small square -/+ used by [OrderItemsTable] when it is editable.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(6.r),
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AdminColors.line),
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: enabled ? AdminColors.ink : AdminColors.muted,
        ),
      ),
    );
  }
}
