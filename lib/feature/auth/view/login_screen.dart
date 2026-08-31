import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kms/core/utils/app_image.dart';

import '../controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Registered by AuthBinding on this route.
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 24.0.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 28.h),

              // Circular image
              Center(
                child: Container(
                  width: 220.w,
                  height: 220.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(18.0.w),
                      child: Image.asset(
                        AppImage.bgSplash,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Center(
                          child: Icon(
                            Icons.image,
                            size: 48.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              // Title
              Text(
                'Joldi Order Dao',
                style: GoogleFonts.openSans(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF116A2A),
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'Order your breakfast quickly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF576B61),
                ),
              ),

              SizedBox(height: 36.h),

              SizedBox(height: 28.h),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: Obx(() {
                  final isLoading = controller.isLoading.value;
                  return ElevatedButton.icon(
                    // A null onPressed also greys the button out, so the
                    // disabled state is visible and not just inert.
                    onPressed: isLoading ? null : controller.signInWithGoogle,
                    icon: isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.login, size: 22.sp, color: Colors.white),
                    label: Text(
                      isLoading ? 'Signing in...' : 'Sign In with Google',
                      style: GoogleFonts.openSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF116A2A),
                      disabledBackgroundColor: const Color(0xFF116A2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 4,
                    ),
                  );
                }),
              ),

              SizedBox(height: 24.h),

              // Small helper text
              Text(
                'By signing in you agree to our Terms & Privacy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 12.sp,
                  color: const Color(0xFF9AA49A),
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
