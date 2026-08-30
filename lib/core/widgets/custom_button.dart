import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/app_color.dart';
import '../utils/app_fonts.dart';

class CustomButton extends StatelessWidget {
  final String? title;
  final TextStyle? titleStyle;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? radius;
  final Color? bgColor;
  final Color? borderColor;
  final Color? loadingColor;
  final String? svgIcon;
  final Color? svgIconColor;
  final double? svgIconHeight;
  final IconData? icon;
  final bool isGradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Replaces the whole label row - use for anything the title/icon props
  /// cannot express.
  final Widget? child;

  const CustomButton({
    super.key,
    this.title,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.height,
    this.bgColor,
    this.titleStyle,
    this.radius,
    this.svgIcon,
    this.icon,
    this.borderColor,
    this.loadingColor,
    this.svgIconColor,
    this.svgIconHeight,
    this.isGradient = false,
    this.padding,
    this.margin,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: isGradient
            ? Colors.transparent
            : (bgColor ?? AppColor.primaryColor),
        borderRadius: BorderRadius.circular(radius ?? 12).r,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius ?? 12).r,
          onTap: isLoading ? null : onTap,
          child: Container(
            height: (height ?? 56).h,
            width: width != null ? width!.w : 1.sw,
            alignment: Alignment.center,
            padding: padding ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: isGradient ? AppColor.primaryGradient : null,
              borderRadius: BorderRadius.circular(radius ?? 12).r,
              border: Border.all(
                color: borderColor ?? bgColor ?? AppColor.primaryColor,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 22.h,
                    width: 22.h,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        loadingColor ?? AppColor.alwaysWhite,
                      ),
                      strokeWidth: 2,
                    ),
                  )
                : child ??
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title ?? '',
                            // The default background is primaryColor, so the
                            // default label is white-on-colour, not the theme
                            // foreground.
                            style:
                                titleStyle ??
                                interSemiBold.copyWith(
                                  color: AppColor.alwaysWhite,
                                ),
                          ),
                          if (svgIcon != null || icon != null)
                            SizedBox(width: 8.w),
                          if (svgIcon != null)
                            SvgPicture.asset(
                              svgIcon!,
                              height: svgIconHeight,
                              colorFilter: svgIconColor != null
                                  ? ColorFilter.mode(
                                      svgIconColor!,
                                      BlendMode.srcIn,
                                    )
                                  : null,
                            ),
                          if (icon != null)
                            Icon(
                              icon,
                              color: AppColor.alwaysWhite,
                              size: 20.sp,
                            ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
