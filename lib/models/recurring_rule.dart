/// A transaction that repeats every month on [dayOfMonth].
///
/// Stored on the user's document under `recurring.<id>`. [lastGenerated] is
/// the last month (first day of it) a record was created for, so catch-up
/// only creates the months after it.
class RecurringRule {
  final String id;
  final bool isIncome;
  final double amount; // expense amount, or gross income
  final double epf;
  final double socso;
  final double pcb;
  final String category;
  final String description;
  final int dayOfMonth;
  final bool isTaxDeductible;
  final DateTime lastGenerated;

  const RecurringRule({
    required this.id,
    required this.isIncome,
    required this.amount,
    this.epf = 0,
    this.socso = 0,
    this.pcb = 0,
    required this.category,
    this.description = '',
    required this.dayOfMonth,
    this.isTaxDeductible = false,
    required this.lastGenerated,
  });

  double get netIncome => amount - epf - socso - pcb;

  Map<String, dynamic> toMap() => {
        'isIncome': isIncome,
        'amount': amount,
        'epf': epf,
        'socso': socso,
        'pcb': pcb,
        'category': category,
        'description': description,
        'dayOfMonth': dayOfMonth,
        'isTaxDeductible': isTaxDeductible,
        'lastGenerated': '${lastGenerated.year}-${lastGenerated.month.toString().padLeft(2, '0')}',
      };

  factory RecurringRule.fromMap(String id, Map<String, dynamic> m) {
    final last = (m['lastGenerated'] as String? ?? '').split('-');
    final now = DateTime.now();
    return RecurringRule(
      id: id,
      isIncome: m['isIncome'] == true,
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      epf: (m['epf'] as num?)?.toDouble() ?? 0,
      socso: (m['socso'] as num?)?.toDouble() ?? 0,
      pcb: (m['pcb'] as num?)?.toDouble() ?? 0,
      category: m['category'] as String? ?? 'Others',
      description: m['description'] as String? ?? '',
      dayOfMonth: (m['dayOfMonth'] as num?)?.toInt() ?? 1,
      isTaxDeductible: m['isTaxDeductible'] == true,
      lastGenerated: last.length == 2
          ? DateTime(int.tryParse(last[0]) ?? now.year, int.tryParse(last[1]) ?? now.month)
          : DateTime(now.year, now.month),
    );
  }

  RecurringRule withLastGenerated(DateTime month) => RecurringRule(
        id: id,
        isIncome: isIncome,
        amount: amount,
        epf: epf,
        socso: socso,
        pcb: pcb,
        category: category,
        description: description,
        dayOfMonth: dayOfMonth,
        isTaxDeductible: isTaxDeductible,
        lastGenerated: DateTime(month.year, month.month),
      );

  /// The dates (one per month) that are due but not yet generated, up to [now].
  ///
  /// A month is due once its day has arrived; short months clamp the day
  /// (e.g. the 31st becomes 30 April / 28 February).
  List<DateTime> dueDates(DateTime now) {
    final result = <DateTime>[];
    var month = DateTime(lastGenerated.year, lastGenerated.month + 1);
    while (!month.isAfter(DateTime(now.year, now.month))) {
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final date = DateTime(month.year, month.month, dayOfMonth.clamp(1, lastDay));
      if (date.isAfter(now)) break;
      result.add(date);
      month = DateTime(month.year, month.month + 1);
    }
    return result;
  }

  /// Deterministic record id, so generating the same month twice overwrites
  /// instead of duplicating.
  String recordIdFor(DateTime date) => 'rec_${id}_${date.year}${date.month.toString().padLeft(2, '0')}';
}
