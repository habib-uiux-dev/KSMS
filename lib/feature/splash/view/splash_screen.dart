import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kms/core/utils/app_image.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/transition/screen_transition.dart';
import '../../../core/utils/app_color.dart';
import '../../../core/utils/app_fonts.dart';
import '../../../core/utils/session_manager.dart';

/// The one screen that decides where the user lands. Keep the branching here
/// so no other screen has to know about login state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _decideNextScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _decideNextScreen() {
    // FirebaseAuth is the source of truth, not the stored flag: it restores the
    // session from disk during initializeApp, and it is what actually decides
    // whether Firestore reads will be allowed. The local flag can go stale
    // (cleared Firebase cache, revoked account) and would strand the user on a
    // home screen that cannot load anything.
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // Keep the mirror honest so anything else reading it agrees.
    SessionManager.setValue(kIsLogin, isLoggedIn);

    ScreenTransition(
      routeName: isLoggedIn ? Routes.home : Routes.login,
      replace: true,
    ).navigate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgColor1,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200.w,
              height: 200.h,
              child: Image.asset(AppImage.bgSplash, fit: BoxFit.cover),
            ),
            SizedBox(height: 20.h),
            Text(
              'KSMS',
              style: interBold.copyWith(
                fontSize: 24.sp,
                color: AppColor.darkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
