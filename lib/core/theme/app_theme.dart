import 'package:flutter/material.dart';

import '../utils/app_palette.dart';

/// ThemeData for the framework-owned surfaces the app never colours by hand:
/// dialogs, bottom sheets, popup menus, text-selection handles, Material
/// defaults inside third-party widgets.
///
/// App widgets keep reading [AppColor]; this only stops stock Material bits
/// from staying white in dark mode.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.bgColor1,
      canvasColor: p.whiteColor,
      dividerColor: p.whiteColor2,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: p.primaryColor,
            brightness: p.brightness,
          ).copyWith(
            primary: p.primaryColor,
            surface: p.whiteColor,
            onSurface: p.darkColor,
            error: p.redColor,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bgColor1,
        foregroundColor: p.darkColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.whiteColor,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.whiteColor,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.whiteColor,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: p.whiteColor,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primaryColor),
      // Ripples read as dirty smudges on dark surfaces at the default opacity.
      splashColor: p.primaryColor.withValues(alpha: isDark ? .08 : .12),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primaryColor,
        selectionHandleColor: p.primaryColor,
      ),
      iconTheme: IconThemeData(color: p.darkColor),
    );
  }
}
