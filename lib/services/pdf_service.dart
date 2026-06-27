import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';

class PdfService {
  static Future<void> generateMonthlyReport({
    required int month,
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM, yyyy').format(DateTime(DateTime.now().year, month));

    final totalIncome = incomes.fold(0.0, (sum, item) => sum + item.netIncome);
    final totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final netSavings = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(color: PdfColors.grey, fontSize: 10),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(color: PdfColors.grey, fontSize: 10),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Branded Top Bar
            pw.Container(
              height: 10,
              width: double.infinity,
              decoration: const pw.BoxDecoration(color: PdfColors.purple700),
            ),
            pw.SizedBox(height: 10),
            pw.Header(
              level: 0,
              decoration: const pw.BoxDecoration(border: null),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Monthly Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
                      pw.Text('Finance Tracker App', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(monthName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Text('Monthly Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(color: PdfColors.green50, border: pw.Border(left: pw.BorderSide(color: PdfColors.green, width: 4))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL INCOME', style: pw.TextStyle(fontSize: 10, color: PdfColors.green900)),
                        pw.Text('RM ${totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(color: PdfColors.red50, border: pw.Border(left: pw.BorderSide(color: PdfColors.red, width: 4))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL EXPENSES', style: pw.TextStyle(fontSize: 10, color: PdfColors.red900)),
                        pw.Text('RM ${totalExpenses.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: netSavings >= 0 ? PdfColors.blue50 : PdfColors.orange50,
                      border: pw.Border(left: pw.BorderSide(color: netSavings >= 0 ? PdfColors.blue : PdfColors.orange, width: 4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NET SAVINGS', style: pw.TextStyle(fontSize: 10, color: netSavings >= 0 ? PdfColors.blue900 : PdfColors.orange900)),
                        pw.Text('RM ${netSavings.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: netSavings >= 0 ? PdfColors.blue900 : PdfColors.orange900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Income Details
            pw.Text('Income Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Description', 'Amount (RM)'],
              data: incomes.map((i) => [
                DateFormat('dd/MM/yyyy').format(i.incomeDate),
                i.category,
                i.description ?? '-',
                i.netIncome.toStringAsFixed(2),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 30),

            // Expense Details
            pw.Text('Expense Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Description', 'Amount (RM)'],
              data: expenses.map((e) => [
                DateFormat('dd/MM/yyyy').format(e.expenseDate),
                e.category,
                e.description ?? '-',
                e.amount.toStringAsFixed(2),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateCategoryReport({
    required int month,
    required String category,
    required List<ExpenseRecord> expenses,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM, yyyy').format(DateTime(DateTime.now().year, month));
    final totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Category Report: $category', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(monthName, style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Transactions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${expenses.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Spent in Category:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('RM ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Description', 'Tax Deductible', 'Amount (RM)'],
              data: expenses.map((e) => [
                DateFormat('dd/MM/yyyy').format(e.expenseDate),
                e.description ?? '-',
                e.isTaxDeductible ? 'Yes' : 'No',
                e.amount.toStringAsFixed(2),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              headerCellDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
