import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase/admin_repository.dart';

/// Owns "is this user an admin" and the unlock flow.
///
/// Registered permanently, because the answer decides whether a button appears
/// on the shop screen and must survive navigation.
class AdminController extends GetxController {
  AdminController({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? AdminRepository();

  final AdminRepository _adminRepository;

  final isAdmin = false.obs;
  final isUnlocking = false.obs;

  StreamSubscription<bool>? _adminSub;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // Re-evaluate on every sign-in / sign-out, otherwise the previous user's
    // admin flag would linger on the next account.
    FirebaseAuth.instance.authStateChanges().listen((_) => _watchAdminFlag());
    _watchAdminFlag();
  }

  @override
  void onClose() {
    _adminSub?.cancel();
    super.onClose();
  }

  void _watchAdminFlag() {
    _adminSub?.cancel();

    final id = uid;
    if (id == null) {
      isAdmin.value = false;
      return;
    }

    // A stream, not a one-off read: revoking `admins/{uid}` in the console
    // locks the app down without waiting for a sign-out.
    _adminSub = _adminRepository
        .watchIsAdmin(id)
        .listen(
          (value) => isAdmin.value = value,
          onError: (Object e) {
            log('Admin flag stream failed: $e');
            isAdmin.value = false;
          },
        );
  }

  /// Returns null when the code was accepted, otherwise a message to show.
  ///
  /// The comparison happens server-side - see [AdminRepository] - so a wrong
  /// code cannot be brute-forced against anything held on the phone.
  Future<String?> unlock(String code) async {
    final id = uid;
    if (id == null) return 'You are signed out';
    if (code.trim().isEmpty) return 'Enter the code';

    isUnlocking.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final errorCode = await _adminRepository.unlockWithCode(
        uid: id,
        code: code.trim(),
        name: user?.displayName,
        email: user?.email,
      );

      if (errorCode == null) {
        isAdmin.value = true;
        return null;
      }

      log('Admin unlock rejected: $errorCode');
      return switch (errorCode) {
        // The rule rejected it. From the client these three causes look
        // identical, so name all of them instead of guessing.
        'permission-denied' =>
          'Rejected. Check the code, that firestore.rules is published, '
              'and that config/admin exists with a `code` field.',
        'unavailable' => 'No connection to Firestore',
        _ => 'Could not unlock ($errorCode)',
      };
    } catch (e) {
      log('Admin unlock failed: $e');
      return 'Could not unlock';
    } finally {
      isUnlocking.value = false;
    }
  }

  Future<void> lock() async {
    final id = uid;
    if (id == null) return;
    try {
      await _adminRepository.revoke(id);
    } catch (e) {
      log('Admin revoke failed: $e');
    } finally {
      isAdmin.value = false;
    }
  }
}
