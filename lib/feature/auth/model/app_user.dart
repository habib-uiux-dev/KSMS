import 'package:cloud_firestore/cloud_firestore.dart';

/// A user document in the `users` collection, keyed by the Firebase Auth uid.
///
/// [designation] is the only field the app itself asks for – everything else
/// comes from the Google account.
class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? designation;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.designation,
    this.createdAt,
    this.lastLoginAt,
  });

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? designation,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) => AppUser(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    designation: designation ?? this.designation,
    createdAt: createdAt ?? this.createdAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    name: map['name'] as String?,
    email: map['email'] as String?,
    photoUrl: map['photo_url'] as String?,
    designation: map['designation'] as String?,
    createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    lastLoginAt: (map['last_login_at'] as Timestamp?)?.toDate(),
  );

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});

  /// Timestamps are left to the server so a device with a wrong clock cannot
  /// write a bogus date. Fields that are null are dropped rather than written
  /// as null, so a merge never wipes an existing value.
  Map<String, dynamic> toCreateMap() => {
    'name': name,
    'email': email,
    'photo_url': photoUrl,
    if (designation != null) 'designation': designation,
    'created_at': FieldValue.serverTimestamp(),
    'last_login_at': FieldValue.serverTimestamp(),
  };

  /// Note what is missing: `name`.
  ///
  /// It is set once, on create, from the Google account. After that the person
  /// owns it - they can edit it in the app, and a later sign-in must not
  /// silently put the Google display name back.
  Map<String, dynamic> toUpdateMap() => {
    if (email != null) 'email': email,
    if (photoUrl != null) 'photo_url': photoUrl,
    if (designation != null) 'designation': designation,
    'last_login_at': FieldValue.serverTimestamp(),
  };
}
