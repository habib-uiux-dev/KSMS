import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Registered by AuthBinding on this route.
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 48.h),

              // ================= TOP TEXT =================
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Healthy & Eating Made\n',
                      style: GoogleFonts.outfit(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE53935),
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'Better ',
                      style: GoogleFonts.outfit(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.soup_kitchen,
                        size: 28.sp,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'Simplify healthy eating with personalized meal plans, recipes, and groceries.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // ================= MIDDLE SVG IMAGE =================
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/Food.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),

      // ================= BOTTOM BAR BUTTON =================
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 58.h,
                child: Obx(() {
                  final isLoading = controller.isLoading.value;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : controller.signInWithGoogle,
                      borderRadius: BorderRadius.circular(30.r),
                      child: Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF3B36),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF3B36).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Left Circle for Google Icon
                            Container(
                              width: 48.w,
                              height: 48.h,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(12.w),
                              child: isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFEF3B36),
                                        ),
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      'assets/images/google-circle.svg',
                                      width: 24.w,
                                      height: 24.h,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.g_mobiledata,
                                        color: Color(0xFFEF3B36),
                                      ),
                                    ),
                            ),

                            // Center Text
                            Expanded(
                              child: Text(
                                isLoading ? 'Signing in...' : 'Login with Google',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(width: 48.w), // Balance spacing on right
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: 14.h),

              // Terms & Privacy
              Text(
                'By signing in you agree to our Terms & Privacy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 12.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
