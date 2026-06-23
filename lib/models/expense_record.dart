import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseRecord {
  final String id;
  final double amount;
  final String category;
  final String? description;
  final DateTime expenseDate;
  final String? proofImagePath;
  final bool isTaxDeductible;
  final DateTime createdAt;

  ExpenseRecord({
    required this.id,
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
    return ExpenseRecord(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? '',
      description: map['description'],
      expenseDate: (map['expenseDate'] as Timestamp).toDate(),
      proofImagePath: map['proofImagePath'],
      isTaxDeductible: map['isTaxDeductible'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
