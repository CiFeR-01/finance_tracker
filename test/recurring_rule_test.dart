import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/recurring_rule.dart';

RecurringRule rule({required int day, required DateTime last}) =>
    RecurringRule(id: 'r1', isIncome: false, amount: 100, category: 'Bills & utilities', dayOfMonth: day, lastGenerated: last);

void main() {
  test('nothing due in the month already generated', () {
    expect(rule(day: 5, last: DateTime(2026, 11)).dueDates(DateTime(2026, 11, 20)), isEmpty);
  });

  test('next month is not due before its day arrives', () {
    expect(rule(day: 15, last: DateTime(2026, 10)).dueDates(DateTime(2026, 11, 10)), isEmpty);
    expect(rule(day: 15, last: DateTime(2026, 10)).dueDates(DateTime(2026, 11, 15)), [DateTime(2026, 11, 15)]);
  });

  test('catches up several missed months, across a year boundary', () {
    final dates = rule(day: 1, last: DateTime(2025, 11)).dueDates(DateTime(2026, 2, 3));
    expect(dates, [DateTime(2025, 12, 1), DateTime(2026, 1, 1), DateTime(2026, 2, 1)]);
  });

  test('day 31 clamps to the end of short months', () {
    final dates = rule(day: 31, last: DateTime(2026, 1)).dueDates(DateTime(2026, 4, 30));
    expect(dates, [DateTime(2026, 2, 28), DateTime(2026, 3, 31), DateTime(2026, 4, 30)]);
  });

  test('round-trips through the stored map and builds stable record ids', () {
    final r = rule(day: 7, last: DateTime(2026, 3));
    final back = RecurringRule.fromMap('r1', r.toMap());
    expect(back.lastGenerated, DateTime(2026, 3));
    expect(back.dayOfMonth, 7);
    expect(r.recordIdFor(DateTime(2026, 4, 7)), 'rec_r1_202604');
  });
}
