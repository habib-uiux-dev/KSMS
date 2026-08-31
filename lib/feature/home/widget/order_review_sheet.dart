import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/image_loader.dart';
import '../controller/home_controller.dart';
import '../model/order.dart';

const Color _green = Color(0xFF116A2A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF6E7A74);
const Color _line = Color(0xFFE8ECE9);
const Color _tile = Color(0xFFF7F8FA);

/// The basket, one last time - and still editable.
///
/// Placing used to be a single tap, which is unforgiving here: one order per
/// person per day, and none of it editable once the cash is collected.
///
/// The first version of this sheet was read-only, which was worse than no
/// sheet: it printed "x2" next to every line and then refused to let anyone
/// touch it, and its second button said "Edit Order" while actually doing
/// nothing but closing. Changing one quantity cost five taps. The rows are the
/// controls now, so what the sheet shows is what it does.
///
/// Returns true when the user confirms.
Future<bool> showOrderReviewSheet(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => const _OrderReviewSheet(),
  );
  return confirmed ?? false;
}

class _OrderReviewSheet extends StatelessWidget {
  const _OrderReviewSheet();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
        // Bound straight to the live cart rather than to a copy: closing the
        // sheet then keeps whatever was changed instead of silently throwing
        // it away, and there is no second source of truth to drift.
        child: Obx(() {
          final items = controller.cartItems;
          final isEditing = controller.isEditingOrder;

          return Column(
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
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Your Order' : 'Review Your Order',
                      style: GoogleFonts.openSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: _green,
                      ),
                    ),
                  ),
                  Text(
                    controller.itemCount == 1
                        ? '1 Item'
                        : '${controller.itemCount} Items',
                    style: GoogleFonts.openSans(
                      fontSize: 13.sp,
                      color: _muted,
                    ),
                  ),
                  // No "Cancel" / "Edit" button any more - both names lied
                  // about what they did. Closing is just closing.
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(Icons.close, size: 20.sp, color: _muted),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                  ),
                ],
              ),
              Divider(height: 1, color: _line),

              // Capped so a long basket scrolls instead of pushing the button
              // off the bottom of the screen.
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 320.h),
                  child: items.isEmpty
                      ? _EmptyCart()
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: _line),
                          itemBuilder: (context, index) => _ItemRow(
                            item: items[index],
                            controller: controller,
                          ),
                        ),
                ),
              ),

              Divider(height: 1, color: _line),
              SizedBox(height: 14.h),

              // No subtotal / tax rows: there is no tax here, and a second
              // line showing the same number as the total is just noise.
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
                    '৳${controller.totalAmount}',
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
                items.isEmpty
                    ? 'Add something before placing the order.'
                    : 'Pay in cash when you collect.',
                style: GoogleFonts.openSans(fontSize: 12.sp, color: _muted),
              ),
              SizedBox(height: 16.h),

              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: items.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFF86C8A2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Update Order' : 'Place Order',
                    style: GoogleFonts.openSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.controller});

  final OrderItem item;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    // Resolved from the live catalogue so the row can call increment/decrement,
    // which take a Product rather than an id.
    final product = controller.products
        .firstWhereOrNull((p) => p.id == item.productId);
    final imageUrl = product?.imageUrl;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: 44.w,
              height: 44.w,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? Container(
                      color: _tile,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.fastfood_outlined,
                        size: 20.sp,
                        color: _muted,
                      ),
                    )
                  : ImageLoader(url: imageUrl, boxFit: BoxFit.cover),
            ),
          ),
          SizedBox(width: 10.w),

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

          if (product != null) ...[
            _StepButton(
              icon: Icons.remove,
              onTap: () => controller.decrement(product),
            ),
            SizedBox(
              width: 28.w,
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: () => controller.increment(product),
            ),
          ] else
            // Product pulled from the catalogue while it sat in the basket.
            // Showing the line without controls beats hiding it, so the total
            // still adds up.
            Text(
              '× ${item.quantity}',
              style: GoogleFonts.openSans(fontSize: 14.sp, color: _muted),
            ),

          SizedBox(width: 10.w),
          SizedBox(
            width: 46.w,
            child: Text(
              '৳${item.lineTotal}',
              textAlign: TextAlign.end,
              style: GoogleFonts.openSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: Container(
        width: 30.w,
        height: 30.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _tile,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _line),
        ),
        child: Icon(icon, size: 16.sp, color: _ink),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 28.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_shopping_cart_outlined, size: 34.sp, color: _muted),
          SizedBox(height: 8.h),
          Text(
            'Your order is empty',
            style: GoogleFonts.openSans(fontSize: 14.sp, color: _muted),
          ),
        ],
      ),
    );
  }
}
