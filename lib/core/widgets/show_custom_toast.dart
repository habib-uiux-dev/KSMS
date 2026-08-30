import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../main.dart';
import '../utils/app_color.dart';
import '../utils/app_fonts.dart';

/// A toast has to stand apart from the page, so it inverts: dark pill on a
/// light app, light pill on a dark one.
void showCustomToast(String message, {int duration = 2}) {
  final fToast = FToast();
  fToast.init(navigatorKey.currentState!.overlay!.context);

  final isDark = AppColor.isDark;
  final background = isDark ? AppColor.whiteColor1 : AppColor.alwaysDark;
  final borderColor = isDark ? AppColor.whiteColor2 : Colors.transparent;
  final textColor = isDark ? AppColor.darkColor : AppColor.alwaysWhite;

  final toast = Container(
    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
    margin: EdgeInsets.symmetric(horizontal: 30.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      color: background,
      // Nothing separates a dark pill from a dark page without an edge.
      border: Border.all(color: borderColor),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: interReg.copyWith(fontSize: 15.sp, height: 1.3, color: textColor),
    ),
  );

  fToast.showToast(
    child: toast,
    gravity: ToastGravity.BOTTOM,
    toastDuration: Duration(seconds: duration),
  );
}
