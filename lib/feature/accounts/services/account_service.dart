import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase/app_firestore.dart';
import '../model/account_entry.dart';

class AccountService {
  final FirebaseFirestore _firestore = appFirestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('accounts');

  /// Stream of all account entries in real-time ordered by date
  Stream<List<AccountEntry>> watchEntries() {
    return _collection.snapshots().map((snapshot) {
      final list = <AccountEntry>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          list.add(AccountEntry.fromJson(data, doc.id));
        } catch (e) {
          log('Error parsing account doc ${doc.id}: $e');
        }
      }
      list.sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  /// Add a Jorimana or Expense entry
  Future<void> addEntry({
    required AccountEntryType type,
    required String name,
    required double amount,
    required DateTime date,
  }) async {
    await _collection.add({
      'type': type == AccountEntryType.expense ? 'expense' : 'jorimana',
      'name': name.trim(),
      'amount': amount,
      'date': date.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing entry
  Future<void> updateEntry({
    required String id,
    required AccountEntryType type,
    required String name,
    required double amount,
    required DateTime date,
  }) async {
    await _collection.doc(id).update({
      'type': type == AccountEntryType.expense ? 'expense' : 'jorimana',
      'name': name.trim(),
      'amount': amount,
      'date': date.toIso8601String(),
    });
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    await _collection.doc(id).delete();
  }
}
