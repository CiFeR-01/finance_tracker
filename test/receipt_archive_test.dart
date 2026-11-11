import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/expense_record.dart';
import 'package:finance_tracker/models/income_record.dart';
import 'package:finance_tracker/services/receipt_archive.dart';

ExpenseRecord exp(String cat, DateTime d, double amt, {bool tax = true, String? proof, String? desc}) => ExpenseRecord(
      id: '$cat$d',
      userId: 'u',
      amount: amt,
      category: cat,
      description: desc,
      expenseDate: d,
      proofImagePath: proof,
      isTaxDeductible: tax,
      createdAt: d,
    );

void main() {
  test('one folder per relief, only deductible records in the year', () {
    final entries = ReceiptArchive.plan(
      year: 2026,
      expenses: [
        exp('Medical expenses', DateTime(2026, 3, 14), 120, proof: '/a/IMG_1.JPG', desc: 'Klinik: Dr. Tan'),
        exp('Medical expenses', DateTime(2026, 3, 14), 120, proof: '/a/IMG_2.jpg', desc: 'Klinik: Dr. Tan'),
        exp('Lifestyle', DateTime(2026, 5, 1), 99.9),
        exp('Groceries', DateTime(2026, 5, 2), 50, tax: false, proof: '/a/x.jpg'),
        exp('Lifestyle', DateTime(2025, 12, 31), 10, proof: '/a/old.jpg'),
      ],
      incomes: [
        IncomeRecord(
          id: 'i', userId: 'u', totalIncome: 5000, epfAmount: 0, socsoAmount: 0, pcbAmount: 0, netIncome: 5000,
          category: 'Salary', incomeDate: DateTime(2026, 1, 25), proofImagePath: '/a/ea.png', createdAt: DateTime(2026),
        ),
      ],
    );
    expect(entries.map((e) => e.zipPath).toList(), [
      'Income/2026-01-25 RM 5000.00 Salary.png',
      'Medical expenses/2026-03-14 RM 120.00 Klinik Dr. Tan.jpg',
      'Medical expenses/2026-03-14 RM 120.00 Klinik Dr. Tan (2).jpg',
      '',
    ]);
    expect(entries.last.hasReceipt, isFalse);

    final csv = ReceiptArchive.indexCsv(entries);
    expect(csv.split('\n')[4], '2026-05-01,Lifestyle,,99.90,MISSING');
  });
}
