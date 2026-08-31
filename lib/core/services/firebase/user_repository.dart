import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../feature/auth/model/app_user.dart';
import 'app_firestore.dart';

/// Every read/write of the `users` collection goes through here, so the
/// collection name and the create-vs-update rule live in one place.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  static const String usersCollection = 'users';

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(usersCollection);

  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Live view of one user document – use with StreamBuilder or `.obs` binding
  /// so a profile edit on another device shows up without a manual refresh.
  Stream<AppUser?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  /// Creates the document on first sign-in, merges on every later one.
  ///
  /// The two paths differ: only a create sets `created_at`, and only a create
  /// may write a null designation. An update merges, so a user who signs in
  /// again without retyping their designation keeps the stored one.
  Future<AppUser> upsertOnSignIn(AppUser user) async {
    final ref = _users.doc(user.uid);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      await ref.set(user.toUpdateMap(), SetOptions(merge: true));
    } else {
      await ref.set(user.toCreateMap());
    }

    final fresh = await ref.get();
    return AppUser.fromDoc(fresh);
  }

  /// Saves whatever the profile sheet changed. Merges, so passing one field
  /// leaves the other alone.
  Future<void> updateProfile(
    String uid, {
    String? name,
    String? designation,
  }) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (designation != null) data['designation'] = designation;
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateDesignation(String uid, String designation) => _users
      .doc(uid)
      .set({'designation': designation}, SetOptions(merge: true));
}
