/// Pulls the useful fields out of OCR text from a printed receipt.
///
/// Pure Dart (no ML Kit), so it can be unit tested. Receipts vary a lot, so
/// every field is a best guess that the user confirms in the form.
class ReceiptData {
  final double? total;
  final DateTime? date;
  final String? merchant;
  const ReceiptData({this.total, this.date, this.merchant});

  bool get isEmpty => total == null && date == null && merchant == null;
}

class ReceiptParser {
  // Words that mark the amount actually paid (English and Malay receipts).
  static final _totalKeywords = RegExp(
    r'\b(grand\s*total|total\s*(amount|due|payable|rm|incl\.?)?|amount\s*due|jumlah(\s*besar|\s*bayaran)?|net\s*total|nett?\s*amt)\b',
    caseSensitive: false,
  );
  // Lines whose number is NOT the total even though they may say "total".
  static final _notTotal = RegExp(
    r'(sub\s*-?\s*total|subtotal|total\s*(qty|quantity|items?|disc|discount|savings?|tax|gst|sst)|change|baki|tunai|cash|rounding|pembundaran|tendered)',
    caseSensitive: false,
  );
  // Amounts like 12.50, 1,234.50, RM12.50, RM 12.50
  static final _money = RegExp(r'(?:RM\s?)?(\d{1,3}(?:,\d{3})+|\d+)[.,](\d{2})(?!\d)', caseSensitive: false);

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'mei': 5, 'jun': 6, 'jul': 7,
    'aug': 8, 'ogo': 8, 'sep': 9, 'oct': 10, 'okt': 10, 'nov': 11, 'dec': 12, 'dis': 12,
  };

  static ReceiptData parse(String text, {DateTime? now}) {
    final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return ReceiptData(
      total: _findTotal(lines),
      date: _findDate(lines, now ?? DateTime.now()),
      merchant: _findMerchant(lines),
    );
  }

  static List<double> _amountsIn(String line) => _money
      .allMatches(line)
      .map((m) => double.tryParse('${m.group(1)!.replaceAll(',', '')}.${m.group(2)}'))
      .whereType<double>()
      .toList();

  static double? _findTotal(List<String> lines) {
    // 1. A "total" line with an amount on it, or on the next line (OCR often
    //    splits label and value). Prefer the last one: grand totals come last.
    double? found;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_totalKeywords.hasMatch(line) || _notTotal.hasMatch(line)) continue;
      var amounts = _amountsIn(line);
      if (amounts.isEmpty && i + 1 < lines.length) amounts = _amountsIn(lines[i + 1]);
      if (amounts.isNotEmpty) found = amounts.last;
    }
    if (found != null) return found;

    // 2. Otherwise the largest amount on the receipt, ignoring cash/change lines.
    final all = <double>[];
    for (final line in lines) {
      if (_notTotal.hasMatch(line)) continue;
      all.addAll(_amountsIn(line));
    }
    if (all.isEmpty) return null;
    all.sort();
    return all.last;
  }

  static DateTime? _findDate(List<String> lines, DateTime now) {
    final numeric = RegExp(r'\b(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{2,4})\b');
    final named = RegExp(r'\b(\d{1,2})[\s\-/]*([A-Za-z]{3})[A-Za-z]*[\s\-/,]*(\d{2,4})\b');
    for (final line in lines) {
      for (final m in numeric.allMatches(line)) {
        final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!), c = int.parse(m.group(3)!);
        // yyyy-mm-dd, else Malaysian dd/mm/yyyy
        final date = m.group(1)!.length == 4 ? _valid(a, b, c, now) : _valid(_year(c), b, a, now);
        if (date != null) return date;
      }
      for (final m in named.allMatches(line)) {
        final month = _months[m.group(2)!.toLowerCase()];
        if (month == null) continue;
        final date = _valid(_year(int.parse(m.group(3)!)), month, int.parse(m.group(1)!), now);
        if (date != null) return date;
      }
    }
    return null;
  }

  static int _year(int y) => y < 100 ? 2000 + y : y;

  static DateTime? _valid(int y, int m, int d, DateTime now) {
    if (m < 1 || m > 12 || d < 1 || d > 31 || y < 2000) return null;
    final date = DateTime(y, m, d);
    if (date.month != m) return null; // e.g. 31/02
    if (date.isAfter(now.add(const Duration(days: 1)))) return null; // receipts aren't from the future
    return date;
  }

  static String? _findMerchant(List<String> lines) {
    // The shop name is usually one of the first lines: take the first that is
    // mostly letters and isn't an address, phone, tax or receipt-number line.
    final skip = RegExp(r'(tel|phone|fax|www\.|http|@|gst|sst|reg|no\.|invoice|receipt|resit|cashier|jalan|jln|lot\s)', caseSensitive: false);
    for (final line in lines.take(6)) {
      final letters = line.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
      if (letters < 3 || letters < line.length * 0.5 || skip.hasMatch(line)) continue;
      return _titleCase(line);
    }
    return null;
  }

  static String _titleCase(String s) {
    if (s != s.toUpperCase()) return s;
    return s.toLowerCase().split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
