import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeRecord {
  final String id;
  final String userId;
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
    required this.userId,
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
      'userId': userId,
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
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return IncomeRecord(
      id: id,
      userId: map['userId'] ?? '',
      totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
      epfAmount: (map['epfAmount'] as num?)?.toDouble() ?? 0.0,
      socsoAmount: (map['socsoAmount'] as num?)?.toDouble() ?? 0.0,
      pcbAmount: (map['pcbAmount'] as num?)?.toDouble() ?? 0.0,
      netIncome: (map['netIncome'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      description: map['description'],
      incomeDate: parseDate(map['incomeDate']),
      proofImagePath: map['proofImagePath'],
      createdAt: parseDate(map['createdAt']),
    );
  }
}
