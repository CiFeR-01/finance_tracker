import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recurring_rule.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import '../viewmodels/home_view_model.dart';

/// Lists monthly recurring transactions and lets the user stop them.
/// New ones are made with "Repeat monthly" on the add forms.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return '$n${switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' }}';
  }

  Future<void> _confirmStop(BuildContext context, HomeViewModel vm, RecurringRule rule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop repeating?'),
        content: Text(
          '${rule.description.isEmpty ? rule.category : rule.description} won\'t be added automatically any more. '
          'Records already created stay in your history.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Stop')),
        ],
      ),
    );
    if (ok == true) await vm.deleteRecurringRule(rule.id);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final rules = vm.recurringRules;
    final app = context.appColors;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      body: rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_repeat_rounded, size: 56, color: colors.outline),
                    const SizedBox(height: AppTheme.space4),
                    Text('No recurring transactions', style: context.text.titleMedium),
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      'When you add income or an expense, turn on "Repeat monthly" and it will be added for you every month.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
              children: [
                Text(
                  'Added automatically each month when the day arrives.',
                  style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.space3),
                Card(
                  child: Column(
                    children: [
                      for (final r in rules)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (r.isIncome ? app.income : app.expense).withValues(alpha: 0.14),
                            child: Icon(r.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                                color: r.isIncome ? app.income : app.expense),
                          ),
                          title: Text(r.description.isEmpty ? r.category : r.description),
                          subtitle: Text('${r.category} · every ${ordinal(r.dayOfMonth)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r.isIncome ? formatRM(r.netIncome, signed: true) : formatRM(-r.amount),
                                style: context.text.titleSmall?.copyWith(
                                  color: r.isIncome ? app.income : colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Stop repeating',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => _confirmStop(context, vm, r),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
