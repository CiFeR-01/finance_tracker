import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/recurring_rule.dart';
import 'package:finance_tracker/services/reminder_planner.dart';

RecurringRule rule(int day, {bool income = false}) => RecurringRule(
      id: 'r$day',
      isIncome: income,
      amount: 1200,
      category: 'Bills & utilities',
      description: 'Rent',
      dayOfMonth: day,
      lastGenerated: DateTime(2026, 10),
    );

void main() {
  final now = DateTime(2026, 11, 10, 12);

  test('nothing is planned when reminders are off', () {
    final r = ReminderPlanner.plan(
      settings: const ReminderSettings(),
      rules: [rule(15)],
      now: now,
      filingDeadline: DateTime(2027, 5, 15),
    );
    expect(r, isEmpty);
  });

  test('bill reminder is the morning before, skipping ones already past', () {
    final r = ReminderPlanner.plan(
      settings: const ReminderSettings(bills: true),
      rules: [rule(5), rule(15), rule(1, income: true)],
      now: now,
    );
    // Day-5 bill: Nov already passed, so Dec, Jan, Feb. Day-15: Nov..Feb.
    expect(r.where((x) => x.when.day == 4).length, 3);
    expect(r.where((x) => x.when.day == 14).length, 4);
    expect(r.first.when, DateTime(2026, 11, 14, 9));
    expect(r.first.title, 'Rent is due tomorrow');
    // Income rules never get a bill reminder.
    expect(r.length, 7);
  });

  test('day 31 bills are clamped to short months', () {
    final r = ReminderPlanner.plan(settings: const ReminderSettings(bills: true), rules: [rule(31)], now: now);
    expect(r.map((x) => x.when).toList(), [
      DateTime(2026, 11, 29, 9),
      DateTime(2026, 12, 30, 9),
      DateTime(2027, 1, 30, 9),
      DateTime(2027, 2, 27, 9),
    ]);
  });

  test('filing reminders before the deadline, with unique ids', () {
    final r = ReminderPlanner.plan(
      settings: const ReminderSettings(bills: true, filing: true),
      rules: [rule(15)],
      now: now,
      filingDeadline: DateTime(2027, 5, 15),
    );
    final filing = r.where((x) => x.title.contains('YA 2026')).toList();
    expect(filing.map((x) => x.when).toList(), [
      DateTime(2027, 3, 1, 9),
      DateTime(2027, 4, 15, 9),
      DateTime(2027, 5, 12, 9),
    ]);
    expect(r.map((x) => x.id).toSet().length, r.length);
  });
}
