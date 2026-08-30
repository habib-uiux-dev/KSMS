import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/widgets/image_loader.dart';
import '../../admin/controller/admin_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/home_controller.dart';
import '../../../core/widgets/show_custom_toast.dart';
import 'widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E8C3A),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Obx(() {
              final url = controller.avatarUrl;
              return CircleAvatar(
                radius: 20.r,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: url != null && url.isNotEmpty
                      ? ImageLoader(url: url, size: 40.sp, boxFit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.white),
                ),
              );
            }),

            SizedBox(width: 12.w),

            Expanded(
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.greetingDesignation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      controller.greetingName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Admin: opens the dashboard once unlocked, asks for the code
            // before that. Deliberately looks the same either way, so the
            // button does not advertise who is an admin.
            Obx(() {
              final admin = Get.find<AdminController>();
              return IconButton(
                onPressed: () => admin.isAdmin.value
                    ? Get.toNamed(Routes.adminShell)
                    : _askForAdminCode(context),
                icon: Icon(
                  admin.isAdmin.value
                      ? Icons.admin_panel_settings
                      : Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                ),
                tooltip: admin.isAdmin.value ? 'Admin' : 'Admin access',
              );
            }),

            IconButton(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Sign out',
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 12.h),

            // ================= SMOKE & TEA BUTTON =================
            /*Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickButton(
                      label: 'Tap For Smoke',
                      color: const Color(0xFFEF4C4C),
                      icon: Icons.smoke_free,
                      onTap: () => controller.quickAdd('smoke'),
                    ),
                  ),

                  const SizedBox(width: 12.w),

                  Expanded(
                    child: _QuickButton(
                      label: 'Tap For Tea',
                      color: const Color(0xFF16A34A),
                      icon: Icons.local_cafe,
                      onTap: () => controller.quickAdd('tea'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12.h),*/

            // ================= CATEGORY CHIPS =================
            SizedBox(
              height: 48.h,
              child: Obx(() {
                final categories = controller.categories;
                // Read the selection HERE, in the Obx builder itself.
                //
                // itemBuilder runs later, during layout, outside the scope Obx
                // watches - so reading selectedCategory in there registered no
                // dependency and the chips kept their first-build colours even
                // though tapping did filter the grid.
                final selected = controller.selectedCategory.value;

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryChip(
                      label: category,
                      selected: selected == category,
                      onTap: () => controller.selectCategory(category),
                    );
                  },
                );
              }),
            ),

            SizedBox(height: 20.h),

            // ================= PRODUCT GRID =================
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = controller.visibleProducts;
                  if (items.isEmpty) {
                    return _EmptyState(
                      message:
                          controller.errorMessage.value ??
                          'No items in this category yet',
                      // Only offer the seed when the whole catalogue is empty -
                      // an empty *category* is not something a retry can fix.
                      onRetry: controller.products.isEmpty
                          ? controller.seedCatalogue
                          : null,
                    );
                  }

                  return GridView.builder(
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) =>
                        ProductCard(product: items[index]),
                  );
                }),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),

      // ================= ORDER SUMMARY =================
      bottomNavigationBar: const _OrderSummaryBar(),
    );
  }

  /// Asks for the secret code and unlocks the admin tabs when it matches.
  ///
  /// The code is verified by a Firestore security rule against a document the
  /// client cannot read, so nothing here - and nothing in the APK - reveals it.
  Future<void> _askForAdminCode(BuildContext context) async {
    final admin = Get.find<AdminController>();
    final field = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Admin access',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: field,
          autofocus: true,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (value) => Navigator.pop(context, value),
          decoration: InputDecoration(
            hintText: 'Secret code',
            hintStyle: GoogleFonts.openSans(color: const Color(0xFF9AA49A)),
          ),
          style: GoogleFonts.openSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.openSans()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: Text(
              'Unlock',
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF116A2A),
              ),
            ),
          ),
        ],
      ),
    );

    if (code == null || code.trim().isEmpty) return;

    final error = await admin.unlock(code);
    if (error == null) {
      showCustomToast('Admin unlocked');
      Get.toNamed(Routes.adminShell);
    } else {
      showCustomToast(error, duration: 5);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign out?',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You will need to sign in with Google again.',
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
              'Sign out',
              style: GoogleFonts.openSans(color: const Color(0xFFEF4C4C)),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    // AuthController is bound to the login route, so it may not exist here.
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    await auth.signOut();
  }
}

// ============================================================
// QUICK ORDER BUTTON
// ============================================================

// Kept while the Smoke/Tea row above is commented out - delete both together
// if the shortcuts are not coming back.
// ignore: unused_element
class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 16.r,
            child: Icon(icon, size: 20.sp, color: color),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORY CHIP
// ============================================================

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF116A2A) : const Color(0xFFEFF6EE),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.openSans(
              color: selected ? Colors.white : const Color(0xFF23332B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(color: const Color(0xFF6E7A74)),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF116A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Add starter catalogue',
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ORDER SUMMARY BAR
// ============================================================

class _OrderSummaryBar extends StatelessWidget {
  const _OrderSummaryBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ================= ORDER INFO =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your Order',
                    style: GoogleFonts.openSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Obx(
                    () => Text(
                      '${controller.itemCount} items selected',
                      style: GoogleFonts.openSans(
                        color: const Color(0xFF6E7A74),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= TOTAL =================
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.openSans(color: const Color(0xFF6E7A74)),
                ),

                SizedBox(height: 4.h),

                Obx(
                  () => Text(
                    '৳${controller.totalAmount}',
                    style: GoogleFonts.openSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF116A2A),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 12.w),

            // ================= PLACE ORDER =================
            SizedBox(
              height: 50.h,
              child: Obx(() {
                final isBusy = controller.isPlacingOrder.value;
                // Deep green once there is something to order, the muted
                // shade while the cart is empty.
                final isEnabled = controller.itemCount > 0 && !isBusy;

                return ElevatedButton(
                  onPressed: isEnabled ? controller.placeOrder : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF116A2A),
                    disabledBackgroundColor: const Color(0xFF86C8A2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 4.w),

                      Text(
                        isBusy ? 'Placing...' : 'Place Order',
                        style: GoogleFonts.openSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(width: 6.w),

                      if (isBusy)
                        SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
