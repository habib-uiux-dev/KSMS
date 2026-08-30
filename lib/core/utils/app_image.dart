/// Every asset path in one place, so a renamed file breaks the build instead
/// of silently rendering an empty box at runtime.
class AppImage {
  AppImage._();

  static const String assetPath = 'assets/images/';

  // SVG icons
  static const String icBack = '${assetPath}ic_back_arrow.svg';
  static const String icHome = '${assetPath}ic_home.svg';
  static const String icSettings = '${assetPath}ic_setting.svg';

  // Raster
  static const String bgSplash = '${assetPath}bg_splash.webp';
}
