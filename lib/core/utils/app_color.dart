import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The single place widgets read colours from.
///
/// These are getters, not `static const`, so pointing [palette] at the dark
/// [AppPalette] recolours the whole app without touching a single call site.
/// The trade-off: they are not reactive, so whoever swaps the palette must
/// force a rebuild – see ThemeController.
class AppColor {
  AppColor._();

  static AppPalette palette = AppPalette.light;

  static bool get isDark => palette.brightness == Brightness.dark;

  /// Fixed colours – these must NOT flip with the theme. Use them for text on
  /// a coloured button, a brand logo plate, anything whose background is the
  /// same in both themes.
  static const Color alwaysWhite = Color(0xFFFFFFFF);
  static const Color alwaysDark = Color(0xFF14161A);
  static const Color alwaysPrimary = Color(0xFF0A79FD);

  /// Brand
  static Color get primaryColor => palette.primaryColor;
  static Color get primaryColor1 => palette.primaryColor1;

  /// Backgrounds
  static Color get bgColor => palette.bgColor;
  static Color get bgColor1 => palette.bgColor1;

  /// Surfaces
  static Color get whiteColor => palette.whiteColor;
  static Color get whiteColor1 => palette.whiteColor1;
  static Color get whiteColor2 => palette.whiteColor2;

  /// Foreground
  static Color get darkColor => palette.darkColor;
  static Color get darkColor2 => palette.darkColor2;

  /// Muted text / dividers
  static Color get grayColor => palette.grayColor;
  static Color get grayColor1 => palette.grayColor1;
  static Color get grayColor2 => palette.grayColor2;

  /// Status
  static Color get greenColor => palette.greenColor;
  static Color get redColor => palette.redColor;
  static Color get yellowColor => palette.yellowColor;

  /// Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [palette.primaryColor, palette.primaryColor1],
  );
}
