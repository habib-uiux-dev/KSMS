import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_firestore.dart';

/// Shop-wide settings that every client is allowed to read.
///
/// Deliberately a different collection from `config`, which holds the admin
/// secret and is closed to all clients. Anything readable by users lives here;
/// anything that must stay hidden lives there.
class SettingsRepository {
  SettingsRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  static const String settingsCollection = 'settings';
  static const String orderingDoc = 'ordering';

  DocumentReference<Map<String, dynamic>> get _ordering =>
      _db.collection(settingsCollection).doc(orderingDoc);

  /// Whether the shop is currently taking orders.
  ///
  /// Missing document means open. Fail-open is the right default here: the
  /// failure mode of fail-closed is an office where nobody can order and nobody
  /// can see why. Only an admin can write this document, so it cannot be
  /// deleted by a user to force the shop open.
  Stream<bool> watchOrderingOpen() => _ordering
      .snapshots()
      .map((doc) => !doc.exists || (doc.data()?['is_open'] as bool? ?? true));

  Future<bool> fetchOrderingOpen() async {
    final doc = await _ordering.get();
    return !doc.exists || (doc.data()?['is_open'] as bool? ?? true);
  }

  Future<void> setOrderingOpen(bool isOpen) => _ordering.set({
    'is_open': isOpen,
    'updated_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
