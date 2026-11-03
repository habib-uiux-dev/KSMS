import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
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
      SessionManager.setValue(SessionManager.designationKey(uid), role);
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
    UserCredential? userCredential;
    String? fallbackDisplayName;
    String? fallbackEmail;
    String? fallbackPhotoUrl;

    try {
      await initGoogleSignIn();

      // First attempt: Credential Manager via GoogleSignIn.authenticate
      if (_googleSignIn.supportsAuthenticate()) {
        try {
          final account = await _googleSignIn.authenticate(
            scopeHint: const ['email'],
          );

          final idToken = account.authentication.idToken;
          if (idToken != null) {
            final credential = GoogleAuthProvider.credential(idToken: idToken);
            userCredential = await FirebaseAuth.instance.signInWithCredential(
              credential,
            );
            fallbackDisplayName = account.displayName;
            fallbackEmail = account.email;
            fallbackPhotoUrl = account.photoUrl;
          }
        } catch (e) {
          log('CredentialManager authenticate threw: $e');
        }
      }
    } catch (e) {
      log('initGoogleSignIn threw: $e');
    }

    // Second attempt: Fallback to FirebaseAuth signInWithProvider (Chrome Custom Tabs).
    // This bypasses Android Credential Manager bugs, Samsung One UI cancellation bugs,
    // and older Play Services limitations.
    if (userCredential == null) {
      try {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await FirebaseAuth.instance.signInWithProvider(
          googleProvider,
        );
      } on FirebaseAuthException catch (e) {
        log('Firebase signInWithProvider failed: ${e.code} ${e.message}');
        if (e.code != 'canceled' &&
            e.code != 'popup-closed-by-user' &&
            e.code != 'web-context-cancelled') {
          showCustomToast(e.message ?? 'Sign in failed');
        }
        isLoading.value = false;
        return;
      } catch (e) {
        log('signInWithProvider general error: $e');
        showCustomToast('Sign in failed: $e');
        isLoading.value = false;
        return;
      }
    }

    try {
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        showCustomToast('Sign in failed: no user returned');
        return;
      }

      appUser.value = await _userRepository.upsertOnSignIn(
        AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? fallbackDisplayName ?? 'Google User',
          email: firebaseUser.email ?? fallbackEmail ?? '',
          photoUrl: firebaseUser.photoURL ?? fallbackPhotoUrl,
        ),
      );

      SessionManager.setValue(kIsLogin, true);

      final localDesignation = SessionManager.getValue(SessionManager.designationKey(firebaseUser.uid)) as String?;
      final bool hasRole = (localDesignation != null && localDesignation.trim().isNotEmpty) ||
          !needsDesignation(appUser.value);

      if (hasRole && appUser.value?.designation != null && appUser.value!.designation!.trim().isNotEmpty) {
        SessionManager.setValue(SessionManager.designationKey(firebaseUser.uid), appUser.value!.designation!.trim());
      }

      ScreenTransition(
        routeName: hasRole ? Routes.home : Routes.designation,
        replace: true,
      ).navigate();
    } on FirebaseException catch (e) {
      log('Firestore write failed: ${e.plugin}/${e.code} ${e.message}');
      showCustomToast(
        'Database error: ${e.code} (${e.message ?? ""})',
        duration: 4,
      );
    } catch (e) {
      log('Sign-in finalization failed: $e');
      showCustomToast('Something went wrong during sign in');
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      // Both sides: Firebase drops the session, Google forgets the account so
      // the next sign-in shows the picker instead of silently reusing it.
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      log('Sign out failed: $e');
    } finally {
      if (uid != null) {
        SessionManager.removeValue(SessionManager.designationKey(uid));
      }
      appUser.value = null;
      SessionManager.removeValue(kIsLogin);
      const ScreenTransition(routeName: Routes.login, replace: true).navigate();
    }
  }
}
