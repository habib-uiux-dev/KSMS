import 'package:flutter/material.dart';

/// Every colour the app uses, once per theme.
///
/// Both instances are `const`, so switching themes swaps a single pointer.
/// Read colours through [AppColor], never from here, so call sites stay
/// theme-agnostic.
class AppPalette {
  final Brightness brightness;

  /// Brand
  final Color primaryColor;
  final Color primaryColor1;

  /// Backgrounds
  final Color bgColor;
  final Color bgColor1;

  /// Surfaces – whiteColor is the card background everywhere
  final Color whiteColor;
  final Color whiteColor1;
  final Color whiteColor2;

  /// Foreground – these invert between themes
  final Color darkColor;
  final Color darkColor2;

  /// Muted text / dividers
  final Color grayColor;
  final Color grayColor1;
  final Color grayColor2;

  /// Status
  final Color greenColor;
  final Color redColor;
  final Color yellowColor;

  const AppPalette({
    required this.brightness,
    required this.primaryColor,
    required this.primaryColor1,
    required this.bgColor,
    required this.bgColor1,
    required this.whiteColor,
    required this.whiteColor1,
    required this.whiteColor2,
    required this.darkColor,
    required this.darkColor2,
    required this.grayColor,
    required this.grayColor1,
    required this.grayColor2,
    required this.greenColor,
    required this.redColor,
    required this.yellowColor,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    primaryColor: Color(0xFF0A79FD),
    primaryColor1: Color(0xFF3D95FE),
    bgColor: Color(0xFFFFFFFF),
    bgColor1: Color(0xFFF6F8FB),
    whiteColor: Color(0xFFFFFFFF),
    whiteColor1: Color(0xFFF2F4F7),
    whiteColor2: Color(0xFFE6E9EF),
    darkColor: Color(0xFF14161A),
    darkColor2: Color(0xFF2B2F36),
    grayColor: Color(0xFF6B7280),
    grayColor1: Color(0xFF8A94A6),
    grayColor2: Color(0xFFB0B7C3),
    greenColor: Color(0xFF17A15A),
    redColor: Color(0xFFE5484D),
    yellowColor: Color(0xFFEECC2C),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF4C9AFF),
    primaryColor1: Color(0xFF74B1FF),
    bgColor: Color(0xFF14161A),
    bgColor1: Color(0xFF0F1115),
    whiteColor: Color(0xFF1B1E24),
    whiteColor1: Color(0xFF23272E),
    whiteColor2: Color(0xFF2E333B),
    darkColor: Color(0xFFF2F4F7),
    darkColor2: Color(0xFFD5D9E0),
    grayColor: Color(0xFF9AA3B2),
    grayColor1: Color(0xFF828B99),
    grayColor2: Color(0xFF5C6472),
    greenColor: Color(0xFF3DD07F),
    redColor: Color(0xFFFF6B6F),
    yellowColor: Color(0xFFF2D65C),
  );
}
