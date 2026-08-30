import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/widgets/image_loader.dart';
import '../../home/model/product.dart';
import '../controller/admin_products_controller.dart';
import 'widgets/admin_widgets.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminProductsController>();

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 90.h),
          children: [
            Text(
              'Products',
              style: GoogleFonts.openSans(
                fontSize: 30.sp,
                fontWeight: FontWeight.w800,
                color: AdminColors.ink,
              ),
            ),
            Text(
              'Manage your inventory',
              style: GoogleFonts.openSans(color: AdminColors.muted),
            ),

            SizedBox(height: 16.h),

            if (controller.products.isEmpty)
              AdminEmpty(
                message: controller.errorMessage.value ?? 'No products yet',
                icon: Icons.inventory_2_outlined,
              )
            else
              for (final product in controller.products)
                _ProductRow(product: product),
          ],
        );
      }),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AdminColors.green,
        onPressed: () {
          // Blank form: startForm with no argument clears every field, so a
          // previous edit cannot leak into a new product.
          controller.startForm();
          Get.toNamed(Routes.adminProductForm);
        },
        child: Icon(Icons.add, color: Colors.white, size: 30.sp),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminProductsController>();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AdminColors.line),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 52.w,
              height: 52.h,
              child: (product.imageUrl?.isNotEmpty ?? false)
                  ? ImageLoader(url: product.imageUrl!, boxFit: BoxFit.cover)
                  : Container(
                      color: AdminColors.tile,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.local_cafe_outlined,
                        color: AdminColors.green,
                        size: 26.sp,
                      ),
                    ),
            ),
          ),

          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.ink,
                  ),
                ),

                SizedBox(height: 6.h),

                // Tapping the badge flips active/draft - the most common edit,
                // so it does not need a trip through the form.
                InkWell(
                  onTap: () => controller.toggleActive(product),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? const Color(0xFFDCFCE7)
                          : AdminColors.amberBg,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      product.isActive ? 'Active' : 'Draft',
                      style: GoogleFonts.openSans(
                        fontWeight: FontWeight.w700,
                        color: product.isActive
                            ? AdminColors.green
                            : AdminColors.amber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '৳${product.price}',
                style: GoogleFonts.openSans(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.green,
                ),
              ),
              IconButton(
                onPressed: () {
                  controller.startForm(product);
                  Get.toNamed(Routes.adminProductForm);
                },
                icon: const Icon(Icons.edit_outlined, color: AdminColors.green),
                tooltip: 'Edit',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
