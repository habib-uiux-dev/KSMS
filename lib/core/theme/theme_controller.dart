import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_color.dart';
import '../utils/app_palette.dart';
import '../utils/session_manager.dart';

const String kThemeMode = 'theme_mode';

/// Owns the app's light/dark/system choice and keeps [AppColor] in sync.
///
/// The app reads colours from `AppColor.x` – a static getter, not an
/// InheritedWidget – so swapping the palette does not by itself mark anything
/// dirty. That is why [setMode] calls `Get.forceAppUpdate()`: it rebuilds every
/// element while leaving the navigation stack alone.
class ThemeController extends GetxController {
  final mode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    // The stored value was already applied in main(); this only mirrors it.
    mode.value = readSavedMode();
  }

  /// Reads the choice without needing the controller – main() calls this
  /// before `runApp` so the first frame is already painted in the right theme.
  static ThemeMode readSavedMode() {
    final saved = SessionManager.getValue(kThemeMode, value: 'light');
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  /// Resolves [ThemeMode.system] against the platform and points [AppColor] at
  /// the matching palette.
  static void applyPalette(ThemeMode themeMode) {
    final isDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
    AppColor.palette = isDark ? AppPalette.dark : AppPalette.light;
  }

  Future<void> setMode(ThemeMode themeMode) async {
    if (mode.value == themeMode) return;

    mode.value = themeMode;
    SessionManager.setValue(kThemeMode, switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });

    applyPalette(themeMode);
    Get.changeThemeMode(themeMode);
    // Static colour getters aren't reactive – force everything to rebuild.
    await Future.microtask(Get.forceAppUpdate);
  }

  /// Called when the OS flips light/dark while we are on [ThemeMode.system].
  void onPlatformBrightnessChanged() {
    if (mode.value != ThemeMode.system) return;
    applyPalette(ThemeMode.system);
    Get.forceAppUpdate();
  }
}
