import 'dart:math' as math;
import '../models/income_record.dart';
import '../models/tax_rates.dart';

/// Income figures for the year, either as recorded or projected to December.
class YearIncome {
  final double gross;
  final double epf;
  final double socso;
  final double pcb;

  /// How many future months of salary were added by the projection (0 if none).
  final int projectedMonths;

  const YearIncome({
    required this.gross,
    required this.epf,
    required this.socso,
    required this.pcb,
    this.projectedMonths = 0,
  });
}

class TaxEstimate {
  final double gross;
  final double reliefs;
  final double donationDeduction;
  final double chargeable;
  final double taxBeforeRebates;
  final double rebates;
  final double taxPayable;
  final double pcbPaid;
  final int projectedMonths;
  final TaxRates rates;

  const TaxEstimate({
    required this.gross,
    required this.reliefs,
    required this.donationDeduction,
    required this.chargeable,
    required this.taxBeforeRebates,
    required this.rebates,
    required this.taxPayable,
    required this.pcbPaid,
    required this.projectedMonths,
    required this.rates,
  });

  /// Positive: you owe this much more. Negative: expected refund.
  double get balance => taxPayable - pcbPaid;
  bool get isRefund => balance < 0;
  bool get isProjected => projectedMonths > 0;
}

class TaxEstimator {
  TaxEstimator._();

  /// Adds up [incomes] for [year]. For the current year, salary is projected
  /// to December using the average of the salary months recorded so far, so
  /// that PCB (deducted on a full-year basis) is compared fairly. Bonuses and
  /// other one-off income are not projected.
  static YearIncome yearIncome(List<IncomeRecord> incomes, int year, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final inYear = incomes.where((i) => i.incomeDate.year == year).toList();
    double sum(Iterable<IncomeRecord> xs, double Function(IncomeRecord) f) => xs.fold(0.0, (s, i) => s + f(i));

    final gross = sum(inYear, (i) => i.totalIncome);
    final epf = sum(inYear, (i) => i.epfAmount);
    final socso = sum(inYear, (i) => i.socsoAmount);
    final pcb = sum(inYear, (i) => i.pcbAmount);

    final salary = inYear.where((i) => i.category == 'Salary').toList();
    if (year != today.year || salary.isEmpty) {
      return YearIncome(gross: gross, epf: epf, socso: socso, pcb: pcb);
    }
    final months = salary.map((i) => i.incomeDate.month).toSet();
    final lastMonth = months.reduce(math.max);
    final remaining = 12 - lastMonth;
    if (remaining <= 0) return YearIncome(gross: gross, epf: epf, socso: socso, pcb: pcb);

    final n = months.length;
    return YearIncome(
      gross: gross + sum(salary, (i) => i.totalIncome) / n * remaining,
      epf: epf + sum(salary, (i) => i.epfAmount) / n * remaining,
      socso: socso + sum(salary, (i) => i.socsoAmount) / n * remaining,
      pcb: pcb + sum(salary, (i) => i.pcbAmount) / n * remaining,
      projectedMonths: remaining,
    );
  }

  /// Works out tax for the year. [reliefs] is the total allowed relief
  /// (already capped per category); [donations] are approved gifts, deducted
  /// up to the rates' cap; [zakat] is a ringgit-for-ringgit rebate.
  static TaxEstimate estimate({
    required YearIncome income,
    required double reliefs,
    required TaxRates rates,
    double donations = 0,
    double zakat = 0,
  }) {
    final donationDeduction = math.min(donations, income.gross * rates.donationCapPercent / 100);
    final chargeable = math.max(0.0, income.gross - donationDeduction - reliefs);
    final tax = rates.taxOn(chargeable);
    final individualRebate = chargeable <= rates.rebateThreshold ? math.min(rates.rebate, tax) : 0.0;
    final zakatRebate = math.min(zakat, tax - individualRebate);
    final rebates = individualRebate + zakatRebate;
    return TaxEstimate(
      gross: income.gross,
      reliefs: reliefs,
      donationDeduction: donationDeduction,
      chargeable: chargeable,
      taxBeforeRebates: tax,
      rebates: rebates,
      taxPayable: tax - rebates,
      pcbPaid: income.pcb,
      projectedMonths: income.projectedMonths,
      rates: rates,
    );
  }
}
