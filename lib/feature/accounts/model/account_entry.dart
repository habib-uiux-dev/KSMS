import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountEntryType { jorimana, expense }

class AccountEntry {
  final String id;
  final AccountEntryType type;
  final String name; // Person name for jorimana, or spent-by/reason for expense
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  AccountEntry({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  factory AccountEntry.fromJson(Map<String, dynamic> json, String docId) {
    return AccountEntry(
      id: docId,
      type: json['type'] == 'expense'
          ? AccountEntryType.expense
          : AccountEntryType.jorimana,
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(json['date']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type == AccountEntryType.expense ? 'expense' : 'jorimana',
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
        'createdAt': createdAt,
      };
}
