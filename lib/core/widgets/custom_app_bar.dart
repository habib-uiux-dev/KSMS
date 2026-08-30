import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';

import '../extensions/color_brightness_extension.dart';
import '../utils/app_color.dart';
import '../utils/app_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool isBackButtonExist;
  final VoidCallback? onBackPressed;
  final Color? bgColor;
  final Color? leadingIconColor;
  final TextStyle? textStyle;
  final Widget? action;
  final double? preferredHeight;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.isBackButtonExist = true,
    this.onBackPressed,
    this.bgColor,
    this.leadingIconColor,
    this.textStyle,
    this.action,
    this.preferredHeight,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = bgColor ?? AppColor.bgColor1;

    return AppBar(
      // Status bar icons have to contrast with whatever colour the bar is,
      // which is not necessarily the theme background.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: barColor,
        statusBarIconBrightness: barColor.isLight
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: barColor.isLight
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: barColor,
        systemNavigationBarIconBrightness: barColor.isLight
            ? Brightness.dark
            : Brightness.light,
      ),
      title:
          titleWidget ??
          Text(
            title ?? '',
            style:
                textStyle ??
                interBold.copyWith(fontSize: 20.sp, color: AppColor.darkColor),
          ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      toolbarHeight: preferredHeight ?? (Platform.isIOS ? 45.h : 50.h),
      leading: isBackButtonExist
          ? IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20.sp,
                color: leadingIconColor ?? AppColor.darkColor,
              ),
              onPressed: onBackPressed ?? Get.back,
            )
          : const SizedBox(),
      leadingWidth: isBackButtonExist ? 44.w : 0,
      backgroundColor: barColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [?action],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    (preferredHeight ?? (Platform.isIOS ? 45.h : 50.h)) +
        (bottom?.preferredSize.height ?? 0),
  );
}
