import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/income_record.dart';
import 'package:finance_tracker/models/tax_rates.dart';
import 'package:finance_tracker/services/tax_estimator.dart';

IncomeRecord salary(int month, {double gross = 5000, double pcb = 100, String cat = 'Salary', int year = 2026}) =>
    IncomeRecord(
      id: '$month$cat',
      userId: 'u',
      totalIncome: gross,
      epfAmount: gross * 0.11,
      socsoAmount: 20,
      pcbAmount: pcb,
      netIncome: 0,
      category: cat,
      incomeDate: DateTime(year, month, 25),
      createdAt: DateTime(year, month, 25),
    );

void main() {
  final rates = TaxRates.bundled(2026);

  test('progressive schedule matches LHDN cumulative figures', () {
    expect(rates.taxOn(5000), 0);
    expect(rates.taxOn(20000), closeTo(150, 0.001));
    expect(rates.taxOn(35000), closeTo(600, 0.001));
    expect(rates.taxOn(50000), closeTo(1500, 0.001));
    expect(rates.taxOn(70000), closeTo(3700, 0.001));
    expect(rates.taxOn(100000), closeTo(9400, 0.001));
  });

  test('owes when PCB is below the tax payable', () {
    final e = TaxEstimator.estimate(
      income: const YearIncome(gross: 60000, epf: 0, socso: 0, pcb: 1000),
      reliefs: 15000,
      rates: rates,
    );
    expect(e.chargeable, 45000);
    expect(e.taxPayable, closeTo(1200, 0.001));
    expect(e.balance, closeTo(200, 0.001));
    expect(e.isRefund, isFalse);
  });

  test('RM 400 rebate under RM 35k, zakat capped at the tax left', () {
    final e = TaxEstimator.estimate(
      income: const YearIncome(gross: 40000, epf: 0, socso: 0, pcb: 300),
      reliefs: 10000,
      rates: rates,
      zakat: 500,
    );
    expect(e.taxBeforeRebates, closeTo(450, 0.001));
    expect(e.taxPayable, 0);
    expect(e.balance, closeTo(-300, 0.001));
    expect(e.isRefund, isTrue);
  });

  test('donations are capped at 10% of income', () {
    final e = TaxEstimator.estimate(
      income: const YearIncome(gross: 50000, epf: 0, socso: 0, pcb: 0),
      reliefs: 0,
      rates: rates,
      donations: 8000,
    );
    expect(e.donationDeduction, 5000);
    expect(e.chargeable, 45000);
  });

  test('salary is projected to December, bonuses are not', () {
    final incomes = [
      for (var m = 1; m <= 10; m++) salary(m),
      salary(3, gross: 10000, pcb: 1000, cat: 'Bonus'),
    ];
    final y = TaxEstimator.yearIncome(incomes, 2026, now: DateTime(2026, 11, 10));
    expect(y.projectedMonths, 2);
    expect(y.gross, closeTo(12 * 5000 + 10000, 0.001));
    expect(y.pcb, closeTo(12 * 100 + 1000, 0.001));
  });

  test('past years are not projected', () {
    final y = TaxEstimator.yearIncome([salary(1, year: 2025)], 2025, now: DateTime(2026, 11, 10));
    expect(y.projectedMonths, 0);
    expect(y.gross, 5000);
  });

  test('a partial tax_config document falls back to bundled values', () {
    final r = TaxRates.fromMap(2027, {'personalRelief': 12000});
    expect(r.personalRelief, 12000);
    expect(r.rebate, 400);
    expect(r.taxOn(100000), closeTo(9400, 0.001));
    final custom = TaxRates.fromMap(2027, {
      'brackets': [
        {'upTo': 10000, 'rate': 0},
        {'upTo': null, 'rate': 10},
      ],
    });
    expect(custom.taxOn(20000), closeTo(1000, 0.001));
  });
}
