/// One band of the resident income tax schedule: income up to [upTo]
/// (null means "and above") is taxed at [rate] percent.
class TaxBracket {
  final double? upTo;
  final double rate;

  const TaxBracket(this.upTo, this.rate);

  Map<String, dynamic> toMap() => {'upTo': upTo, 'rate': rate};

  factory TaxBracket.fromMap(Map<String, dynamic> m) =>
      TaxBracket((m['upTo'] as num?)?.toDouble(), (m['rate'] as num).toDouble());
}

/// The LHDN figures the tax estimate depends on for one year of assessment.
///
/// The app ships with [bundled] values, and the same shape can be stored in
/// Firestore at `tax_config/{year}` so the rates can be updated after each
/// Budget without releasing a new app version.
class TaxRates {
  /// The year of assessment these figures apply to.
  final int year;
  final List<TaxBracket> brackets;

  /// Individual rebate, given when chargeable income is at most [rebateThreshold].
  final double rebate;
  final double rebateThreshold;

  /// Basic individual relief (replaces the profile's fixed amount).
  final double personalRelief;

  /// Approved donations are deductible up to this percent of income.
  final double donationCapPercent;

  /// The e-Filing (BE form) deadline for this year's return, if known.
  final DateTime? filingDeadline;

  const TaxRates({
    required this.year,
    required this.brackets,
    this.rebate = 400,
    this.rebateThreshold = 35000,
    this.personalRelief = 9000,
    this.donationCapPercent = 10,
    this.filingDeadline,
  });

  /// Progressive tax on [chargeable] income.
  double taxOn(double chargeable) {
    var tax = 0.0;
    var lower = 0.0;
    for (final b in brackets) {
      if (chargeable <= lower) break;
      final top = b.upTo ?? double.infinity;
      final inBand = (chargeable < top ? chargeable : top) - lower;
      tax += inBand * b.rate / 100;
      lower = top;
    }
    return tax;
  }

  Map<String, dynamic> toMap() => {
        'brackets': brackets.map((b) => b.toMap()).toList(),
        'rebate': rebate,
        'rebateThreshold': rebateThreshold,
        'personalRelief': personalRelief,
        'donationCapPercent': donationCapPercent,
        if (filingDeadline != null) 'filingDeadline': filingDeadline!.toIso8601String().substring(0, 10),
      };

  /// Reads a `tax_config/{year}` document. Any missing field falls back to
  /// the bundled value, so a partial document is safe.
  factory TaxRates.fromMap(int year, Map<String, dynamic> m) {
    final base = TaxRates.bundled(year);
    double num_(String k, double fallback) => (m[k] as num?)?.toDouble() ?? fallback;
    final rawBrackets = m['brackets'];
    return TaxRates(
      year: year,
      brackets: rawBrackets is List && rawBrackets.isNotEmpty
          ? rawBrackets.map((b) => TaxBracket.fromMap(Map<String, dynamic>.from(b as Map))).toList()
          : base.brackets,
      rebate: num_('rebate', base.rebate),
      rebateThreshold: num_('rebateThreshold', base.rebateThreshold),
      personalRelief: num_('personalRelief', base.personalRelief),
      donationCapPercent: num_('donationCapPercent', base.donationCapPercent),
      filingDeadline: DateTime.tryParse(m['filingDeadline']?.toString() ?? '') ?? base.filingDeadline,
    );
  }

  /// The newest year of assessment the bundled figures are known to cover.
  static const int latestKnownYear = 2026;

  /// True when [year] is newer than the bundled figures, so the estimate is
  /// using last known rates and may be out of date.
  static bool isBeyondKnown(int year) => year > latestKnownYear;

  /// Resident rates for YA 2023 to YA 2026 (unchanged across those years).
  /// Source: LHDN schedule as reported for YA 2025 and YA 2026. Check again
  /// after each Budget; Budget 2027 proposes changes from YA 2027.
  static const List<TaxBracket> _schedule2023 = [
    TaxBracket(5000, 0),
    TaxBracket(20000, 1),
    TaxBracket(35000, 3),
    TaxBracket(50000, 6),
    TaxBracket(70000, 11),
    TaxBracket(100000, 19),
    TaxBracket(400000, 25),
    TaxBracket(600000, 26),
    TaxBracket(2000000, 28),
    TaxBracket(null, 30),
  ];

  factory TaxRates.bundled(int year) => TaxRates(
        year: year,
        brackets: _schedule2023,
        // BE form e-Filing is normally due 30 April, with a two-week grace
        // period that LHDN usually grants for e-Filing (15 May).
        filingDeadline: DateTime(year + 1, 5, 15),
      );
}
