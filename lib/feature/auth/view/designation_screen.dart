import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/auth_controller.dart';

const Color _green = Color(0xFF116A2A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF576B61);
const Color _border = Color(0xFFBFD6C6);

/// One-time onboarding: which team the person is on.
///
/// This used to sit on the login screen, in front of the Google button, which
/// meant everyone retyped it on every sign-in - and there was no way to skip
/// it, because before signing in the app does not know who is asking. Asking
/// afterwards lets it check the profile first, so it appears exactly once per
/// account and survives a reinstall.
class DesignationScreen extends StatelessWidget {
  const DesignationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 56.h),

              Container(
                width: 64.w,
                height: 64.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(Icons.badge_outlined, size: 30.sp, color: _green),
              ),

              SizedBox(height: 20.h),
              Text(
                'One last thing',
                style: GoogleFonts.openSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Pick your team so your orders show up under the right name on '
                'the leaderboard. You only do this once.',
                style: GoogleFonts.openSans(
                  fontSize: 14.sp,
                  height: 1.5,
                  color: _muted,
                ),
              ),

              SizedBox(height: 32.h),
              Text(
                'Designation',
                style: GoogleFonts.openSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374B41),
                ),
              ),
              SizedBox(height: 12.h),

              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.designation.value,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF3A4F42),
                  ),
                  hint: Text(
                    'Select your role',
                    style: GoogleFonts.openSans(
                      color: const Color(0xFF9AA49A),
                      fontSize: 16.sp,
                    ),
                  ),
                  items: AuthController.designations
                      .map(
                        (role) => DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role,
                            style: GoogleFonts.openSans(
                              fontSize: 16.sp,
                              color: _ink,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: controller.selectDesignation,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF3A4F42),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18.h,
                      horizontal: 16.w,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: _border.withValues(alpha: 0.7),
                        width: 1.2.w,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: _border.withValues(alpha: 0.7),
                        width: 1.2.w,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: Obx(() {
                  final isLoading = controller.isLoading.value;
                  final hasRole = (controller.designation.value ?? '')
                      .isNotEmpty;

                  return ElevatedButton(
                    onPressed: isLoading || !hasRole
                        ? null
                        : controller.submitDesignation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: const Color(0xFF86C8A2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.openSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  );
                }),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
