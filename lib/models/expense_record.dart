import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseRecord {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String? description;
  final DateTime expenseDate;
  final String? proofImagePath;
  final bool isTaxDeductible;
  final DateTime createdAt;

  ExpenseRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description,
    required this.expenseDate,
    this.proofImagePath,
    required this.isTaxDeductible,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'proofImagePath': proofImagePath,
      'isTaxDeductible': isTaxDeductible,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExpenseRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return ExpenseRecord(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      description: map['description'],
      expenseDate: parseDate(map['expenseDate']),
      proofImagePath: map['proofImagePath'],
      isTaxDeductible: map['isTaxDeductible'] ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
