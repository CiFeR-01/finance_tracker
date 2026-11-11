import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/expense_record.dart';
import 'package:finance_tracker/models/income_record.dart';
import 'package:finance_tracker/services/csv_export.dart';

void main() {
  test('escapes commas, quotes and formula injection', () {
    expect(CsvExport.escape('plain'), 'plain');
    expect(CsvExport.escape('a,b'), '"a,b"');
    expect(CsvExport.escape('say "hi"'), '"say ""hi"""');
    expect(CsvExport.escape('=SUM(A1)'), "'=SUM(A1)");
    expect(CsvExport.escape('-12.50'), '-12.50');
    expect(CsvExport.escape('-cmd'), "'-cmd");
  });

  test('builds rows oldest first with signed amounts', () {
    final csv = CsvExport.build(
      incomes: [
        IncomeRecord(id: 'i', userId: 'u', totalIncome: 5000, epfAmount: 550, socsoAmount: 20, pcbAmount: 100,
            netIncome: 4330, category: 'Salary', incomeDate: DateTime(2026, 11, 1), createdAt: DateTime(2026, 11, 1)),
      ],
      expenses: [
        ExpenseRecord(id: 'e', userId: 'u', amount: 12.5, category: 'Food & dining', description: 'Nasi lemak, teh',
            expenseDate: DateTime(2026, 11, 3), isTaxDeductible: false, createdAt: DateTime(2026, 11, 3)),
      ],
    );
    final lines = csv.trim().split('\n');
    expect(lines, hasLength(3));
    expect(lines[1], '2026-11-01,Income,Salary,,4330.00,5000.00,550.00,20.00,100.00,');
    expect(lines[2], '2026-11-03,Expense,Food & dining,"Nasi lemak, teh",-12.50,,,,,No');
  });
}
