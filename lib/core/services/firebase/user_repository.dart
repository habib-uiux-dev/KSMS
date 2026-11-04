import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../feature/auth/model/app_user.dart';
import '../../utils/user_filter.dart';
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

  // ------------------------------------------------------------ push tokens

  /// Records which device this person is currently carrying.
  ///
  /// Written by the owner into their own document, so it needs no new
  /// security rule - `users/{uid}` already allows a self-write.
  Future<void> saveFcmToken(String uid, String token) => _users.doc(uid).set({
    'fcm_token': token,
    'fcm_token_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  /// Everyone the admin can currently push to.
  ///
  /// Reading the whole collection is allowed for an admin and nobody else
  /// (`allow read: if isAdmin()`), which is what makes per-device sending
  /// possible at all. Users without a token - never opened the app since this
  /// feature shipped - are simply absent, and the send screen says how many
  /// that is rather than pretending everyone is covered.
  static final RegExp _cleanRegex = RegExp(r'[^a-zA-Z0-9\s]');
  static const Set<String> _commonTitles = {
    'md',
    'dr',
    'mr',
    'mrs',
    'ms',
    'engr',
  };

  static String _cleanString(String? s) {
    if (s == null) return '';
    return s.toLowerCase().replaceAll(_cleanRegex, ' ').trim();
  }

  /// Checks if a user document matches any of the allowed target identifiers.
  static bool matchesUser({
    required Set<String> allowedIdentifiers,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    if (allowedIdentifiers.isEmpty) return false;

    final id = data['id']?.toString().trim();
    final uid = data['uid']?.toString().trim();
    final email = data['email']?.toString().trim();
    final name = (data['name'] ?? data['displayName'])?.toString().trim();

    if (UserFilter.isExcluded(uid: docId, name: name, email: email) ||
        (uid != null && UserFilter.isExcluded(uid: uid, name: name, email: email)) ||
        (id != null && UserFilter.isExcluded(uid: id, name: name, email: email))) {
      return false;
    }

    // 1. Direct exact ID / UID match
    if (allowedIdentifiers.contains(docId) ||
        (id != null && allowedIdentifiers.contains(id)) ||
        (uid != null && allowedIdentifiers.contains(uid))) {
      return true;
    }

    // 2. Direct exact email match (case-insensitive)
    final lowerDocEmail = email?.toLowerCase();
    if (lowerDocEmail != null && lowerDocEmail.isNotEmpty) {
      for (final raw in allowedIdentifiers) {
        if (raw.trim().toLowerCase() == lowerDocEmail) return true;
      }
    }

    // 3. Name & Smart Alias matching
    final cleanDocName = _cleanString(name);
    final cleanDocEmailUname =
        lowerDocEmail != null ? lowerDocEmail.split('@').first : '';
    final docWords = cleanDocName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_commonTitles.contains(w))
        .toList();

    for (final raw in allowedIdentifiers) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed == docId ||
          (id != null && trimmed == id) ||
          (uid != null && trimmed == uid)) {
        return true;
      }
      if (name != null && trimmed.toLowerCase() == name.toLowerCase()) {
        return true;
      }

      final cleanTarget = _cleanString(trimmed);
      if (cleanTarget.isEmpty) continue;

      if (cleanDocName.isNotEmpty) {
        if (cleanDocName == cleanTarget) return true;

        final targetWords = cleanTarget
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty && !_commonTitles.contains(w))
            .toList();

        for (final tw in targetWords) {
          if (tw.length < 3) continue;
          for (final dw in docWords) {
            if (dw.length < 3) continue;
            if (tw == dw) return true;
            if (tw.length >= 4 &&
                dw.length >= 4 &&
                (tw.startsWith(dw) ||
                    dw.startsWith(tw) ||
                    tw.contains(dw) ||
                    dw.contains(tw))) {
              return true;
            }
          }
          if (cleanDocEmailUname.isNotEmpty &&
              tw.length >= 4 &&
              cleanDocEmailUname.contains(tw)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Everyone the admin can currently push to.
  ///
  /// Reading the whole collection is allowed for an admin and nobody else
  /// (`allow read: if isAdmin()`), which is what makes per-device sending
  /// possible at all. Users without a token - never opened the app since this
  /// feature shipped - are simply absent, and the send screen says how many
  /// that is rather than pretending everyone is covered.
  Future<List<PushTarget>> fetchPushTargets({Set<String>? allowedUids}) async {
    if (allowedUids != null && allowedUids.isEmpty) {
      return const [];
    }
    final snapshot = await _users.get();

    final targets = <PushTarget>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (UserFilter.isExcluded(
        uid: doc.id,
        name: data['name'] as String?,
        email: data['email'] as String?,
      )) {
        continue;
      }

      if (allowedUids != null) {
        final isAllowed = matchesUser(
          allowedIdentifiers: allowedUids,
          docId: doc.id,
          data: data,
        );
        if (!isAllowed) {
          continue;
        }
      }

      final token = data['fcm_token'] as String?;
      if (token == null || token.isEmpty) continue;

      targets.add((
        uid: doc.id,
        name: (data['name'] as String?) ?? 'Someone',
        token: token,
      ));
    }
    return targets;
  }

  /// How many people have an account at all, token or not. The send screen
  /// shows it beside the token count so a gap is visible.
  Future<int> countUsers() async => (await _users.count().get()).count ?? 0;
}

/// One device an admin can push to.
typedef PushTarget = ({String uid, String name, String token});
