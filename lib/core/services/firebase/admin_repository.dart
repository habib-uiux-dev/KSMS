import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_firestore.dart';

/// The admin gate.
///
/// The secret code is **never** shipped in the app and never readable by a
/// client. It lives in `config/admin`, which security rules close to everyone.
/// To unlock, the phone writes `admins/{uid}` with the typed code attached;
/// the rule compares it against `config/admin` server-side and rejects the
/// write when it does not match. So a wrong code fails as permission-denied,
/// and nobody can pull the code out of the APK or read it out of Firestore.
class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  static const String adminsCollection = 'admins';

  DocumentReference<Map<String, dynamic>> _admin(String uid) =>
      _db.collection(adminsCollection).doc(uid);

  Future<bool> isAdmin(String uid) async {
    final doc = await _admin(uid).get();
    return doc.exists;
  }

  /// Live admin flag, so revoking access from the console takes effect without
  /// the admin having to sign out.
  Stream<bool> watchIsAdmin(String uid) =>
      _admin(uid).snapshots().map((doc) => doc.exists);

  /// Returns null on success, otherwise the Firestore error code.
  ///
  /// The distinction matters while setting this up: `permission-denied` means
  /// the rule rejected the write - either the code is wrong, the rules are not
  /// published, or `config/admin` does not exist - while anything else
  /// (`unavailable`, `not-found`) is an infrastructure problem, and collapsing
  /// them all into "wrong code" sends you hunting in the wrong place.
  Future<String?> unlockWithCode({
    required String uid,
    required String code,
    String? name,
    String? email,
  }) async {
    try {
      await _admin(uid).set({
        'code': code,
        'name': name,
        'email': email,
        'granted_at': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return e.code;
    }
  }

  Future<void> revoke(String uid) => _admin(uid).delete();
}
