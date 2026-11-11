import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/home_view_model.dart';

/// Reminder switches plus a peek at what is coming up (Profile tab).
class RemindersCard extends StatelessWidget {
  const RemindersCard({super.key});

  Future<void> _toggle(BuildContext context, {bool? bills, bool? filing}) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<HomeViewModel>().setReminder(bills: bills, filing: filing);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Notifications are off for this app. Turn them on in your phone settings.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final settings = vm.reminderSettings;
    final billCount = vm.recurringRules.where((r) => !r.isIncome).length;
    final upcoming = vm.upcomingReminders.take(3).toList();
    final colors = context.colors;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.receipt_long_outlined),
            title: const Text('Bills due'),
            subtitle: Text(billCount == 0
                ? 'For expenses set to repeat monthly'
                : 'The day before each of your $billCount monthly bill${billCount == 1 ? '' : 's'}'),
            value: settings.bills,
            onChanged: (v) => _toggle(context, bills: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.event_available_outlined),
            title: const Text('Tax filing deadline'),
            subtitle: Text('Due ${DateFormat('d MMM yyyy').format(HomeViewModel.nextFilingDeadline(DateTime.now()))}'),
            value: settings.filing,
            onChanged: (v) => _toggle(context, filing: v),
          ),
          if (upcoming.isNotEmpty) ...[
            const Divider(indent: AppTheme.space4, endIndent: AppTheme.space4),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space3, AppTheme.space4, AppTheme.space1),
              child: Text('Coming up', style: context.text.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
            ),
            for (final r in upcoming)
              ListTile(
                dense: true,
                leading: SizedBox(
                  width: 64,
                  child: Text(DateFormat('d MMM').format(r.when),
                      style: context.text.labelLarge?.copyWith(color: colors.primary)),
                ),
                title: Text(r.title),
              ),
            const SizedBox(height: AppTheme.space2),
          ],
        ],
      ),
    );
  }
}
