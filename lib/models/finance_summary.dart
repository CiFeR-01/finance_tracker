class FinanceSummary {
  final String title;
  final String amount;
  final bool isNegative;

  FinanceSummary({
    required this.title,
    required this.amount,
    this.isNegative = false,
  });
}
