import 'package:intl/intl.dart';

final NumberFormat _rm = NumberFormat.currency(locale: 'en_US', symbol: 'RM ', decimalDigits: 2);
final NumberFormat _rmWhole = NumberFormat.currency(locale: 'en_US', symbol: 'RM ', decimalDigits: 0);

/// Formats [amount] as Malaysian Ringgit, e.g. `RM 12,345.00`.
///
/// With [signed] true, positive amounts get a `+` and negative a `-`.
/// With [whole] true, cents are dropped (for chart labels and limits).
String formatRM(double amount, {bool signed = false, bool whole = false}) {
  final f = whole ? _rmWhole : _rm;
  final body = f.format(amount.abs());
  if (amount < 0) return '-$body';
  if (signed && amount > 0) return '+$body';
  return body;
}
