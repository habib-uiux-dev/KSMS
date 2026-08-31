import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kms/core/services/notifications/awesome_notification_service.dart';
import 'package:kms/core/services/notifications/notification_service.dart';
import 'package:kms/firebase_options.dart';

import 'core/bindings/initial_binding.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/session_manager.dart';

/// Toasts and dialogs need an overlay context from outside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.initialize();
  await AwesomeNotificationService.initialize();
  // No options passed: Android reads android/app/google-services.json and iOS
  // reads ios/Runner/GoogleService-Info.plist. Must finish before runApp so
  // the splash screen can read FirebaseAuth.currentUser synchronously.
  // await Firebase.initializeApp();

  await GetStorage.init();
  await SessionManager.init();

  // Resolve the saved theme before runApp so the first frame is already
  // painted in the right palette - no white flash on a dark-mode launch.
  final savedThemeMode = ThemeController.readSavedMode();
  ThemeController.applyPalette(savedThemeMode);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp(themeMode: savedThemeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode themeMode;

  const MyApp({super.key, required this.themeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The OS flipped light/dark. Only matters while the user is on "system".
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (Get.isRegistered<ThemeController>()) {
      Get.find<ThemeController>().onPlatformBrightnessChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Every .w / .h / .sp in the app is measured against this canvas.
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MediaQuery(
          // Pin the text scale so the OS font-size setting cannot break
          // layouts that are already scaled by ScreenUtil.
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: GetMaterialApp(
            builder: FToastBuilder(),
            debugShowCheckedModeBanner: false,
            initialBinding: InitialBinding(),
            initialRoute: Routes.splash,
            navigatorKey: navigatorKey,
            defaultTransition: Transition.native,
            getPages: AppPages.pages,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: widget.themeMode,
          ),
        );
      },
    );
  }
}
