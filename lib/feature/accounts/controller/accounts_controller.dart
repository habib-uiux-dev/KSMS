import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import '../model/account_entry.dart';
import '../services/account_service.dart';

class AccountsController extends GetxController {
  final AccountService _service = AccountService();

  final entries = <AccountEntry>[].obs;
  final isLoading = true.obs;

  StreamSubscription<List<AccountEntry>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _listenToEntries();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _listenToEntries() {
    _sub?.cancel();
    _sub = _service.watchEntries().listen((list) {
      entries.value = list;
      isLoading.value = false;
    }, onError: (e) {
      log('Error in watchEntries stream: $e');
      isLoading.value = false;
    });
  }

  /// Total Jorimana collected
  double get totalJorimana {
    return entries
        .where((e) => e.type == AccountEntryType.jorimana)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Total Expense spent
  double get totalExpense {
    return entries
        .where((e) => e.type == AccountEntryType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Net balance: totalJorimana - totalExpense
  double get netBalance => totalJorimana - totalExpense;

  /// Add Jorimana with optimistic local update
  Future<void> addJorimana({
    required String name,
    required double amount,
    required DateTime date,
  }) async {
    final newEntry = AccountEntry(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      type: AccountEntryType.jorimana,
      name: name,
      amount: amount,
      date: date,
      createdAt: DateTime.now(),
    );

    entries.insert(0, newEntry);
    entries.refresh();

    try {
      await _service.addEntry(
        type: AccountEntryType.jorimana,
        name: name,
        amount: amount,
        date: date,
      );
    } catch (e) {
      log('Error saving jorimana: $e');
      entries.removeWhere((e) => e.id == newEntry.id);
      entries.refresh();
      rethrow;
    }
  }

  /// Add Expense with optimistic local update
  Future<void> addExpense({
    required String spentBy,
    required double amount,
    required DateTime date,
  }) async {
    final newEntry = AccountEntry(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      type: AccountEntryType.expense,
      name: spentBy,
      amount: amount,
      date: date,
      createdAt: DateTime.now(),
    );

    entries.insert(0, newEntry);
    entries.refresh();

    try {
      await _service.addEntry(
        type: AccountEntryType.expense,
        name: spentBy,
        amount: amount,
        date: date,
      );
    } catch (e) {
      log('Error saving expense: $e');
      entries.removeWhere((e) => e.id == newEntry.id);
      entries.refresh();
      rethrow;
    }
  }

  /// Update an existing entry
  Future<void> updateEntry({
    required String id,
    required AccountEntryType type,
    required String name,
    required double amount,
    required DateTime date,
  }) async {
    final index = entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final old = entries[index];
      entries[index] = AccountEntry(
        id: id,
        type: type,
        name: name,
        amount: amount,
        date: date,
        createdAt: old.createdAt,
      );
      entries.refresh();
    }

    try {
      await _service.updateEntry(
        id: id,
        type: type,
        name: name,
        amount: amount,
        date: date,
      );
    } catch (e) {
      log('Error updating entry $id: $e');
    }
  }

  /// Delete entry
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    entries.refresh();
    try {
      await _service.deleteEntry(id);
    } catch (e) {
      log('Error deleting entry $id: $e');
    }
  }
}
