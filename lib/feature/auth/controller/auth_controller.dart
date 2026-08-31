import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/services/firebase/user_repository.dart';
import '../../../core/transition/screen_transition.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/session_manager.dart';
import '../../../core/widgets/show_custom_toast.dart';
import '../model/app_user.dart';

/// Google sign-in, Firebase Auth and the user document, in that order.
///
/// There is no app backend: Firebase Auth is the identity, Firestore is the
/// database. Nothing here calls ApiClient.
class AuthController extends GetxController {
  AuthController({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  final UserRepository _userRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;


  static const List<String> designations = [
    'Mobile App Dev',
    'PHP Dev (SPRO)',
    'PHP Dev (CRM)',
    'Dot Net Dev',
    'AI Dev',
    'UI/UX Designer',
  ];

  /// Collected before the Google sheet opens, so it can be written together
  /// with the profile on first sign-in.
  final designation = RxnString();

  final isLoading = false.obs;
  final appUser = Rxn<AppUser>();

  bool _googleReady = false;

  @override
  void onInit() {
    super.onInit();
    initGoogleSignIn();
  }

  void selectDesignation(String? value) => designation.value = value;

  /// True when the account has no role stored yet - the only time the picker
  /// is shown.
  static bool needsDesignation(AppUser? user) =>
      user == null || (user.designation ?? '').trim().isEmpty;

  /// Saves the onboarding answer and moves on. Returns nothing: failures are
  /// reported by toast and leave the user on the step to retry.
  Future<void> submitDesignation() async {
    if (isLoading.value) return;

    final role = designation.value;
    if (role == null || role.isEmpty) {
      showCustomToast('Choose your designation first');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showCustomToast('You are signed out');
      const ScreenTransition(routeName: Routes.login, replace: true).navigate();
      return;
    }

    isLoading.value = true;
    try {
      await _userRepository.updateDesignation(uid, role);
      appUser.value = await _userRepository.fetchUser(uid);
      const ScreenTransition(routeName: Routes.home, replace: true).navigate();
    } on FirebaseException catch (e) {
      log('Save designation failed: ${e.code} ${e.message}');
      showCustomToast('Could not save (${e.code})');
    } catch (e) {
      log('Save designation failed: $e');
      showCustomToast('Could not save your designation');
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> initGoogleSignIn() async {
    if (_googleReady) return;
    try {
      await _googleSignIn.initialize(
        clientId: GetPlatform.isIOS ? Constants.googleIosClientId : null,
        serverClientId: GetPlatform.isAndroid
            ? Constants.googleServerClientId
            : null,
      );
      _googleReady = true;
    } catch (e) {
      log('Google Sign-In initialize failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      await initGoogleSignIn();

      if (!_googleSignIn.supportsAuthenticate()) {
        showCustomToast('Google sign-in is not supported on this device');
        return;
      }

      // Throws GoogleSignInException instead of returning null on cancel.
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        // Almost always a missing/incorrect serverClientId.
        showCustomToast('Could not get a Google token. Check the client ID.');
        return;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        showCustomToast('Sign in failed');
        return;
      }

      appUser.value = await _userRepository.upsertOnSignIn(
        AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? account.displayName,
          email: firebaseUser.email ?? account.email,
          photoUrl: firebaseUser.photoURL ?? account.photoUrl,
        ),
      );

      SessionManager.setValue(kIsLogin, true);

      // The role is asked for once, and only when the profile hasn't got one.
      // Reading it back from the document rather than from local storage is
      // what makes it survive a reinstall: the answer lives with the account.
      ScreenTransition(
        routeName: needsDesignation(appUser.value)
            ? Routes.designation
            : Routes.home,
        replace: true,
      ).navigate();
    } on GoogleSignInException catch (e) {
      // A cancel is a normal outcome, not an error worth a toast.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        log('Google sign-in failed: ${e.code} ${e.description}');
        // The bare message is useless while wiring up client IDs and SHA-1s,
        // so debug builds surface the actual code.
        showCustomToast(
          kDebugMode
              ? 'Google sign-in failed: ${e.code.name}\n${e.description ?? ''}'
              : 'Google sign-in failed',
          duration: kDebugMode ? 5 : 2,
        );
      }
    } on FirebaseAuthException catch (e) {
      log('Firebase sign-in failed: ${e.code} ${e.message}');
      showCustomToast(e.message ?? 'Sign in failed');
    } on FirebaseException catch (e) {
      // Firestore, not auth: the account is signed in but the profile write
      // failed. 'unavailable' here almost always means the Firestore database
      // has not been created for the project yet, not that the phone is offline.
      log('Firestore write failed: ${e.plugin}/${e.code} ${e.message}');
      showCustomToast(
        kDebugMode
            ? 'Firestore ${e.code}: check the database exists and rules allow this user'
            : 'Could not save your profile. Try again.',
        duration: kDebugMode ? 5 : 2,
      );
    } catch (e) {
      log('Sign-in failed: $e');
      showCustomToast('Something went wrong');
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads the signed-in user's document – call after a cold start when
  /// FirebaseAuth already has a session.
  Future<AppUser?> loadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    appUser.value = await _userRepository.fetchUser(uid);
    return appUser.value;
  }

  Future<void> signOut() async {
    try {
      // Both sides: Firebase drops the session, Google forgets the account so
      // the next sign-in shows the picker instead of silently reusing it.
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      log('Sign out failed: $e');
    } finally {
      appUser.value = null;
      SessionManager.removeValue(kIsLogin);
      const ScreenTransition(routeName: Routes.login, replace: true).navigate();
    }
  }
}
