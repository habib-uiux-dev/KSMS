import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/image_loader.dart';
import '../../controller/home_controller.dart';
import '../../model/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= PRODUCT IMAGE =================
          //
          // The image takes whatever height is left after the details, rather
          // than claiming a fixed 4:3 slice. With a fixed ratio the two
          // together could exceed the grid cell (its height is fixed by
          // childAspectRatio) and overflow; this way the text always gets the
          // room it needs and only the image shrinks.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: SizedBox(
                width: double.infinity,
                child: _ProductImage(product: product),
              ),
            ),
          ),

          // ================= PRODUCT DETAILS =================
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2540),
                  ),
                ),

                SizedBox(height: 4.h),

                Text(
                  product.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(color: const Color(0xFF6E7A74)),
                ),

                // A Spacer would throw here: this Column is MainAxisSize.min,
                // so there is no free space for it to eat.
                SizedBox(height: 10.h),

                // ================= PRICE + QUANTITY =================
                Row(
                  children: [
                    Text(
                      '৳${product.price}',
                      style: GoogleFonts.openSans(
                        fontSize: 16.sp,
                        color: const Color(0xFF116A2A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    // Quantity Controller
                    //
                    // The whole control sits inside one Obx, not just the
                    // number: the minus button's enabled state depends on the
                    // quantity too, and an Obx that only wraps the Text
                    // leaves the button stuck in its first-build state.
                    Obx(() {
                      final quantity = controller.quantityOf(product.id);

                      return Container(
                        height: 38.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus
                            IconButton(
                              // Disabled at zero, so the button greys out
                              // instead of silently doing nothing.
                              onPressed: quantity == 0
                                  ? null
                                  : () => controller.decrement(product),
                              constraints: BoxConstraints(
                                minWidth: 32.w,
                                minHeight: 32.h,
                              ),
                              padding: EdgeInsets.zero,
                              splashRadius: 18.r,
                              icon: Icon(
                                Icons.remove,
                                size: 17.sp,
                                color: Color(0xFF2A4B42),
                              ),
                              disabledColor: const Color(0xFFB4C4BD),
                            ),

                            // Quantity
                            Text(
                              '$quantity',
                              style: GoogleFonts.openSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            // Plus
                            IconButton(
                              onPressed: () => controller.increment(product),
                              constraints: BoxConstraints(
                                minWidth: 32.w,
                                minHeight: 32.h,
                              ),
                              padding: EdgeInsets.zero,
                              splashRadius: 18.r,
                              icon: Icon(
                                Icons.add,
                                size: 17.sp,
                                color: Color(0xFF2A4B42),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Falls back to a tinted initial when a product has no photo yet - an empty
/// grey box reads as a loading failure, a letter reads as "no image".
class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ImageLoader(url: url, boxFit: BoxFit.cover);
    }

    return Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: Text(
        product.name.isEmpty
            ? '?'
            : product.name.characters.first.toUpperCase(),
        style: GoogleFonts.openSans(
          fontSize: 34.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF86C8A2),
        ),
      ),
    );
  }
}
