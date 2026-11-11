import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/recurring_rule.dart';
import '../theme/formatters.dart';

/// Which reminders the user has switched on (stored on users/{uid}.settings).
class ReminderSettings {
  final bool bills;
  final bool filing;

  const ReminderSettings({this.bills = false, this.filing = false});

  factory ReminderSettings.fromMap(Map<String, dynamic> m) =>
      ReminderSettings(bills: m['billReminders'] == true, filing: m['filingReminders'] == true);

  bool get any => bills || filing;
}

class PlannedReminder {
  final int id;
  final DateTime when;
  final String title;
  final String body;

  const PlannedReminder(this.id, this.when, this.title, this.body);

  @override
  String toString() => '$when $title: $body';
}

/// Works out which notifications to schedule. Pure, so it is unit-tested;
/// ReminderService hands the result to the OS.
class ReminderPlanner {
  ReminderPlanner._();

  /// Hour of day reminders are shown.
  static const int hour = 9;

  /// Bill reminders are planned this many months ahead. The app re-plans on
  /// every launch, so this only needs to cover a long gap between launches.
  static const int monthsAhead = 3;

  static List<PlannedReminder> plan({
    required ReminderSettings settings,
    required List<RecurringRule> rules,
    required DateTime now,
    DateTime? filingDeadline,
  }) {
    final out = <PlannedReminder>[];
    var id = 1;

    if (settings.bills) {
      for (final rule in rules.where((r) => !r.isIncome)) {
        for (var m = 0; m <= monthsAhead; m++) {
          final month = DateTime(now.year, now.month + m);
          final lastDay = DateTime(month.year, month.month + 1, 0).day;
          final due = DateTime(month.year, month.month, math.min(rule.dayOfMonth, lastDay));
          // Remind the morning of the day before it is due.
          final when = DateTime(due.year, due.month, due.day - 1, hour);
          if (!when.isAfter(now)) continue;
          final name = rule.description.isNotEmpty ? rule.description : rule.category;
          out.add(PlannedReminder(id++, when, '$name is due tomorrow',
              '${formatRM(rule.amount)} · ${rule.category}. It will be added to your expenses automatically.'));
        }
      }
    }

    if (settings.filing && filingDeadline != null) {
      final ya = filingDeadline.year - 1;
      final due = DateFormat('d MMMM').format(filingDeadline);
      final steps = <(DateTime, String, String)>[
        (DateTime(filingDeadline.year, 3, 1, hour), 'e-Filing for YA $ya is open',
            'Your reliefs are in the Tax tab. Filing early means an earlier refund.'),
        (filingDeadline.subtract(const Duration(days: 30)).copyWith(hour: hour), 'A month left to file YA $ya',
            'e-Filing closes $due.'),
        (filingDeadline.subtract(const Duration(days: 3)).copyWith(hour: hour), '3 days left to e-File YA $ya',
            'e-Filing closes $due. Filing late can mean a penalty.'),
      ];
      for (final (at, title, body) in steps) {
        if (at.isAfter(now)) out.add(PlannedReminder(id++, at, title, body));
      }
    }

    out.sort((a, b) => a.when.compareTo(b.when));
    return out;
  }
}
