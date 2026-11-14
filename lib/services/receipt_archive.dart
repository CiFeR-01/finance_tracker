import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_record.dart';
import '../models/income_record.dart';
import 'csv_export.dart';
import 'temp_file_cleaner.dart';

/// One file going into the receipts zip.
class ArchiveEntry {
  /// Path inside the zip, e.g. `Medical expenses/2026-03-14 RM 120.00 Clinic.jpg`.
  final String zipPath;

  /// Photo on the phone, or null when the record has no receipt attached.
  final String? sourcePath;
  final DateTime date;
  final String category;
  final String description;
  final double amount;

  const ArchiveEntry({
    required this.zipPath,
    required this.sourcePath,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
  });

  bool get hasReceipt => sourcePath != null;
}

/// Bundles a year's tax-relief receipts into one zip, one folder per relief,
/// with an index CSV. This is what LHDN asks for if a return is audited
/// (records are to be kept for 7 years).
class ReceiptArchive {
  ReceiptArchive._();

  /// Works out the zip layout for [year]. Pure, so it is unit-tested.
  /// Only tax-deductible expenses are included, plus income proofs
  /// (payslips / EA form) under `Income/`.
  static List<ArchiveEntry> plan({
    required int year,
    required List<ExpenseRecord> expenses,
    required List<IncomeRecord> incomes,
  }) {
    final day = DateFormat('yyyy-MM-dd');
    final used = <String>{};
    String unique(String path) {
      var candidate = path;
      var n = 2;
      while (!used.add(candidate.toLowerCase())) {
        final ext = p.extension(path);
        candidate = '${p.withoutExtension(path)} ($n)$ext';
        n++;
      }
      return candidate;
    }

    ArchiveEntry entry(String folder, DateTime date, double amount, String category, String? desc, String? proof) {
      final label = _safe(desc?.isNotEmpty == true ? desc! : category);
      final ext = proof == null ? '' : (p.extension(proof).isEmpty ? '.jpg' : p.extension(proof).toLowerCase());
      final name = '${day.format(date)} RM ${amount.toStringAsFixed(2)} $label$ext';
      return ArchiveEntry(
        zipPath: proof == null ? '' : unique('${_safe(folder)}/$name'),
        sourcePath: proof,
        date: date,
        category: category,
        description: desc ?? '',
        amount: amount,
      );
    }

    final out = <ArchiveEntry>[
      for (final e in expenses.where((e) => e.isTaxDeductible && e.expenseDate.year == year))
        entry(e.category, e.expenseDate, e.amount, e.category, e.description, e.proofImagePath),
      for (final i in incomes.where((i) => i.incomeDate.year == year && i.proofImagePath != null))
        entry('Income', i.incomeDate, i.totalIncome, i.category, i.description, i.proofImagePath),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Index of every entry, including ones with no receipt so gaps are visible.
  static String indexCsv(List<ArchiveEntry> entries) {
    final day = DateFormat('yyyy-MM-dd');
    final b = StringBuffer()..writeln(['Date', 'Category', 'Description', 'Amount (RM)', 'Receipt file'].join(','));
    for (final e in entries) {
      b.writeln([
        day.format(e.date),
        e.category,
        e.description,
        e.amount.toStringAsFixed(2),
        e.hasReceipt ? e.zipPath : 'MISSING',
      ].map(CsvExport.escape).join(','));
    }
    return b.toString();
  }

  /// Makes a file or folder name safe on Windows, macOS and Android.
  static String _safe(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length > 40 ? cleaned.substring(0, 40).trim() : cleaned;
  }

  /// Builds the zip and opens the share sheet. Returns how many receipts
  /// were missing (no photo, or the photo is no longer on the phone).
  static Future<int> share({
    required int year,
    required List<ExpenseRecord> expenses,
    required List<IncomeRecord> incomes,
  }) async {
    final entries = plan(year: year, expenses: expenses, incomes: incomes);
    final archive = Archive();
    final kept = <ArchiveEntry>[];
    var missing = 0;
    for (final e in entries) {
      final file = e.sourcePath == null ? null : File(e.sourcePath!);
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(e.zipPath, bytes.length, bytes));
        kept.add(e);
      } else {
        missing++;
        kept.add(ArchiveEntry(
          zipPath: '',
          sourcePath: null,
          date: e.date,
          category: e.category,
          description: e.description,
          amount: e.amount,
        ));
      }
    }
    // BOM so Excel opens the UTF-8 index correctly.
    final indexBytes = utf8.encode('\uFEFF${indexCsv(kept)}');
    archive.addFile(ArchiveFile('index.csv', indexBytes.length, indexBytes));

    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/Tax receipts YA $year.zip');
    try {
      await out.writeAsBytes(ZipEncoder().encodeBytes(archive));
      await SharePlus.instance.share(ShareParams(
        files: [XFile(out.path, mimeType: 'application/zip')],
        subject: 'Tax relief receipts YA $year',
      ));
    } finally {
      // Security: always remove the receipts zip after sharing.
      await TempFileCleaner.deleteFile(out);
    }
    return missing;
  }
}