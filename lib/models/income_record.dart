import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeRecord {
  final String id;
  final double totalIncome;
  final double epfAmount;
  final double socsoAmount;
  final double pcbAmount;
  final double netIncome;
  final String category;
  final String? description;
  final DateTime incomeDate;
  final String? proofImagePath;
  final DateTime createdAt;

  IncomeRecord({
    required this.id,
    required this.totalIncome,
    required this.epfAmount,
    required this.socsoAmount,
    required this.pcbAmount,
    required this.netIncome,
    required this.category,
    this.description,
    required this.incomeDate,
    this.proofImagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalIncome': totalIncome,
      'epfAmount': epfAmount,
      'socsoAmount': socsoAmount,
      'pcbAmount': pcbAmount,
      'netIncome': netIncome,
      'category': category,
      'description': description,
      'incomeDate': Timestamp.fromDate(incomeDate),
      'proofImagePath': proofImagePath,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory IncomeRecord.fromMap(String id, Map<String, dynamic> map) {
    return IncomeRecord(
      id: id,
      totalIncome: (map['totalIncome'] as num).toDouble(),
      epfAmount: (map['epfAmount'] as num).toDouble(),
      socsoAmount: (map['socsoAmount'] as num).toDouble(),
      pcbAmount: (map['pcbAmount'] as num).toDouble(),
      netIncome: (map['netIncome'] as num).toDouble(),
      category: map['category'] ?? '',
      description: map['description'],
      incomeDate: (map['incomeDate'] as Timestamp).toDate(),
      proofImagePath: map['proofImagePath'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
