import 'dart:async';

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kms/core/utils/app_image.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/transition/screen_transition.dart';
import '../../../core/services/firebase/user_repository.dart';
import '../../../core/utils/app_color.dart';
import '../../auth/controller/auth_controller.dart';
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

  Future<void> _decideNextScreen() async {
    // FirebaseAuth is the source of truth, not the stored flag: it restores the
    // session from disk during initializeApp, and it is what actually decides
    // whether Firestore reads will be allowed. The local flag can go stale
    // (cleared Firebase cache, revoked account) and would strand the user on a
    // home screen that cannot load anything.
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    // Keep the mirror honest so anything else reading it agrees.
    SessionManager.setValue(kIsLogin, isLoggedIn);

    if (!isLoggedIn) {
      const ScreenTransition(routeName: Routes.login, replace: true).navigate();
      return;
    }

    // Someone who quit part-way through onboarding is signed in but has no
    // role yet. Sending them to home would leave them nameless on the
    // leaderboard with no way back to the question.
    //
    // A failed read is treated as "has a role": the home screen degrades
    // gracefully, whereas a network blip should not force the picker again.
    var needsRole = false;
    final savedDesignation = SessionManager.getValue(SessionManager.designationKey(user.uid)) as String?;
    if (savedDesignation != null && savedDesignation.trim().isNotEmpty) {
      needsRole = false;
    } else {
      try {
        final profile = await UserRepository().fetchUser(user.uid);
        needsRole = AuthController.needsDesignation(profile);
        if (!needsRole && profile?.designation != null && profile!.designation!.trim().isNotEmpty) {
          SessionManager.setValue(SessionManager.designationKey(user.uid), profile.designation!.trim());
        }
      } catch (e) {
        log('Profile check failed: $e');
      }
    }

    if (!mounted) return;
    ScreenTransition(
      routeName: needsRole ? Routes.designation : Routes.home,
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
