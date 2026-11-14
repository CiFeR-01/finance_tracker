import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_record.dart';
import '../models/income_record.dart';
import 'temp_file_cleaner.dart';

/// Builds a spreadsheet-friendly CSV of transactions and opens the share sheet
/// (save to Files/Drive, email, open in Excel or Google Sheets).
class CsvExport {
  static const header = [
    'Date', 'Type', 'Category', 'Description', 'Amount (RM)', 'Gross income (RM)',
    'EPF (RM)', 'SOCSO (RM)', 'PCB (RM)', 'Tax deductible',
  ];

  /// The CSV text, oldest first. Expenses are negative amounts so a SUM
  /// column gives the net balance.
  static String build({required List<IncomeRecord> incomes, required List<ExpenseRecord> expenses}) {
    final day = DateFormat('yyyy-MM-dd');
    String money(double v) => v.toStringAsFixed(2);
    final rows = <(DateTime, List<String>)>[
      for (final i in incomes)
        (i.incomeDate, [
          day.format(i.incomeDate), 'Income', i.category, i.description ?? '', money(i.netIncome),
          money(i.totalIncome), money(i.epfAmount), money(i.socsoAmount), money(i.pcbAmount), '',
        ]),
      for (final e in expenses)
        (e.expenseDate, [
          day.format(e.expenseDate), 'Expense', e.category, e.description ?? '', money(-e.amount),
          '', '', '', '', e.isTaxDeductible ? 'Yes' : 'No',
        ]),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final buffer = StringBuffer()..writeln(header.map(escape).join(','));
    for (final r in rows) {
      buffer.writeln(r.$2.map(escape).join(','));
    }
    return buffer.toString();
  }

  /// Quotes a field when it contains a comma, quote or newline, and defuses
  /// leading = + - @ so spreadsheets don't run text as a formula.
  static String escape(String field) {
    var f = field;
    if (f.isNotEmpty && '=+@\t\r'.contains(f[0])) f = "'$f";
    if (f.startsWith('-') && double.tryParse(f) == null) f = "'$f";
    if (f.contains(RegExp(r'[",\n\r]'))) f = '"${f.replaceAll('"', '""')}"';
    return f;
  }

  /// Writes the CSV to a temp file, opens the system share sheet, and then
  /// deletes the temp file so financial data is not left in the cache.
  static Future<void> share({
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
    required String fileLabel,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/finance_tracker_$fileLabel.csv');
    try {
      // BOM so Excel opens UTF-8 text correctly.
      await file.writeAsString('\uFEFF${build(incomes: incomes, expenses: expenses)}');
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Finance Tracker export ($fileLabel)',
      ));
    } finally {
      // Security: always remove the exported file after sharing.
      await TempFileCleaner.deleteFile(file);
    }
  }
}