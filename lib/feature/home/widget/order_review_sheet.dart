import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/image_loader.dart';
import '../model/order.dart';

const Color _green = Color(0xFF116A2A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF6E7A74);
const Color _line = Color(0xFFE8ECE9);
const Color _tile = Color(0xFFF7F8FA);

/// Last look before the order leaves the phone.
///
/// Placing used to be a single tap, which is unforgiving here: there is one
/// order per person per day, and once the cash is collected it can't be edited
/// at all. A short read-back costs a second and prevents a wrong basket.
///
/// Returns true when the user confirms.
Future<bool> showOrderReviewSheet(
  BuildContext context, {
  required List<OrderItem> items,
  required int total,
  required bool isEditing,

  /// Thumbnails live on Product, not on OrderItem, so the caller resolves them.
  required String? Function(String productId) imageUrlFor,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => _OrderReviewSheet(
      items: items,
      total: total,
      isEditing: isEditing,
      imageUrlFor: imageUrlFor,
    ),
  );
  return confirmed ?? false;
}

class _OrderReviewSheet extends StatelessWidget {
  const _OrderReviewSheet({
    required this.items,
    required this.total,
    required this.isEditing,
    required this.imageUrlFor,
  });

  final List<OrderItem> items;
  final int total;
  final bool isEditing;
  final String? Function(String productId) imageUrlFor;

  int get _count => items.fold(0, (running, item) => running + item.quantity);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Review Your Changes' : 'Review Your Order',
                    style: GoogleFonts.openSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ),
                Text(
                  _count == 1 ? '1 Item' : '$_count Items',
                  style: GoogleFonts.openSans(fontSize: 13.sp, color: _muted),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: _line),

            // Capped so a long basket scrolls instead of pushing the buttons
            // off the bottom of the screen.
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 320.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: _line),
                  itemBuilder: (context, index) => _ItemRow(
                    item: items[index],
                    imageUrl: imageUrlFor(items[index].productId),
                  ),
                ),
              ),
            ),

            Divider(height: 1, color: _line),
            SizedBox(height: 14.h),

            // No subtotal / tax rows: there is no tax here, and a second line
            // showing the same number as the total is just noise.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.openSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                Text(
                  '৳$total',
                  style: GoogleFonts.openSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'Pay in cash when you collect.',
              style: GoogleFonts.openSans(fontSize: 12.sp, color: _muted),
            ),
            SizedBox(height: 18.h),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Edit Order',
                        style: GoogleFonts.openSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Order' : 'Place Order',
                        style: GoogleFonts.openSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.imageUrl});

  final OrderItem item;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: 44.w,
              height: 44.w,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? Container(
                      color: _tile,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.fastfood_outlined,
                        size: 20.sp,
                        color: _muted,
                      ),
                    )
                  : ImageLoader(url: imageUrl!, boxFit: BoxFit.cover),
            ),
          ),
          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '৳${item.price} / each',
                  style: GoogleFonts.openSans(fontSize: 12.sp, color: _muted),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: _tile,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'x${item.quantity}',
              style: GoogleFonts.openSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          Text(
            '৳${item.lineTotal}',
            style: GoogleFonts.openSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}
