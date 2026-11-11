import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/services/receipt_parser.dart';

void main() {
  final now = DateTime(2026, 11, 10);

  test('reads total, date and shop from a typical Malaysian receipt', () {
    const text = '''
KEDAI RUNCIT AH HOCK
No. 12, Jalan Bunga 3
Tel: 03-1234 5678
SST Reg No: W10-1808-31000000
Date: 08/11/2026 14:32
Milo 1kg        23.90
Roti Gardenia    4.50
Sub Total       28.40
SST 6%           0.00
Rounding        -0.00
TOTAL RM        28.40
Cash            50.00
Change          21.60
''';
    final r = ReceiptParser.parse(text, now: now);
    expect(r.total, 28.40);
    expect(r.date, DateTime(2026, 11, 8));
    expect(r.merchant, 'Kedai Runcit Ah Hock');
  });

  test('total label and amount split across lines', () {
    const text = 'CAFE 99\nLatte 12.00\nCroissant 8.50\nGrand Total\n20.50\nCash 50.00\nChange 29.50';
    expect(ReceiptParser.parse(text, now: now).total, 20.50);
  });

  test('Malay "Jumlah" and thousands separator', () {
    const text = 'Jumlah Besar RM1,234.50\nTunai RM1,300.00\nBaki RM65.50';
    expect(ReceiptParser.parse(text, now: now).total, 1234.50);
  });

  test('falls back to the largest amount when there is no total line', () {
    const text = 'ITEM A 3.20\nITEM B 15.80\nCASH 20.00';
    expect(ReceiptParser.parse(text, now: now).total, 15.80);
  });

  test('named-month and ISO dates; rejects future and invalid dates', () {
    expect(ReceiptParser.parse('5 Nov 2026', now: now).date, DateTime(2026, 11, 5));
    expect(ReceiptParser.parse('2026-10-31 10:00', now: now).date, DateTime(2026, 10, 31));
    expect(ReceiptParser.parse('31/02/2026', now: now).date, isNull);
    expect(ReceiptParser.parse('01/12/2026', now: now).date, isNull);
    expect(ReceiptParser.parse('03/11/26', now: now).date, DateTime(2026, 11, 3));
  });

  test('empty text gives an empty result', () {
    expect(ReceiptParser.parse('', now: now).isEmpty, isTrue);
  });
}
