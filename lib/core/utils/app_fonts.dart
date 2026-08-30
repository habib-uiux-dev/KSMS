import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color.dart';

/// Text styles are built once per app start, so they capture whatever palette
/// was active then. Always `.copyWith(color: ...)` at the call site when the
/// colour matters – don't rely on the baked-in default.
final interReg = GoogleFonts.inter(
  fontWeight: FontWeight.w400,
  fontSize: 16.sp,
  height: 1.h,
  color: AppColor.darkColor,
);

final interMedium = GoogleFonts.inter(
  fontWeight: FontWeight.w500,
  fontSize: 16.sp,
  height: 1.h,
  color: AppColor.darkColor,
);

final interSemiBold = GoogleFonts.inter(
  fontWeight: FontWeight.w600,
  fontSize: 16.sp,
  height: 1.h,
  color: AppColor.darkColor,
);

final interBold = GoogleFonts.inter(
  fontWeight: FontWeight.w700,
  fontSize: 18.sp,
  height: 1.h,
  color: AppColor.darkColor,
);

final interExtraBold = GoogleFonts.inter(
  fontWeight: FontWeight.w800,
  fontSize: 18.sp,
  height: 1.h,
  color: AppColor.darkColor,
);

String capitalizeFirstLetterOfEachWord(String input) {
  if (input.isEmpty) return '';
  return input
      .split(' ')
      .map(
        (word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}

String capitalizeFirstLetter(String input) {
  if (input.isEmpty) return '';
  return input[0].toUpperCase() + input.substring(1);
}
