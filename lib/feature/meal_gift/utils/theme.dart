import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class AppTheme {
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
  );

  static ElevatedButtonThemeData get elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
    ),
  );

  static CardThemeData get cardTheme => CardThemeData(
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.r),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    color: Colors.white,
    margin: EdgeInsets.only(bottom: 16.h),
  );
}
