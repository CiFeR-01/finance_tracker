import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/categories.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import '../viewmodels/home_view_model.dart';

/// Set a monthly spending limit per expense category and see how much of
/// each is used in the selected month.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  Future<void> _edit(BuildContext context, HomeViewModel vm, String category) async {
    final current = vm.budgets[category];
    final controller = TextEditingController(text: current == null ? '' : current.toStringAsFixed(0));
    final result = await showDialog<_BudgetResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(labelText: 'Monthly limit', prefixText: 'RM '),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(context, const _BudgetResult(null)),
              child: Text('Remove', style: TextStyle(color: context.colors.error)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () {
              final v = double.tryParse(controller.text);
              Navigator.pop(context, _BudgetResult(v == null || v <= 0 ? null : v));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await vm.setBudget(category, result.limit);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save budget: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final spent = vm.spentByCategory;
    final totalBudget = vm.budgets.values.fold(0.0, (a, b) => a + b);
    final totalSpentInBudgets = vm.budgets.keys.fold(0.0, (a, k) => a + (spent[k] ?? 0));

    // Budgeted categories first, then the rest in their usual order.
    final ordered = [
      ...expenseCategories.where(vm.budgets.containsKey),
      ...expenseCategories.where((c) => !vm.budgets.containsKey(c)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Budgets · ${DateFormat('MMM yyyy').format(vm.selectedPeriod)}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
        children: [
          if (vm.budgets.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budgeted spending', style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: AppTheme.space1),
                    Text('${formatRM(totalSpentInBudgets)} of ${formatRM(totalBudget)}', style: context.text.titleLarge),
                    const SizedBox(height: AppTheme.space3),
                    _BudgetBar(ratio: totalBudget == 0 ? 0 : totalSpentInBudgets / totalBudget),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space4),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space4),
              child: Text(
                'Tap a category to set a monthly limit. You\'ll see a warning on Home when you reach 90% of it.',
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          Card(
            child: Column(
              children: [
                for (final c in ordered)
                  BudgetTile(
                    category: c,
                    limit: vm.budgets[c],
                    spent: spent[c] ?? 0,
                    onTap: () => _edit(context, vm, c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetResult {
  final double? limit;
  const _BudgetResult(this.limit);
}

/// One category row: name, spent vs limit, and a progress bar.
class BudgetTile extends StatelessWidget {
  final String category;
  final double? limit;
  final double spent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const BudgetTile({
    super.key,
    required this.category,
    required this.limit,
    required this.spent,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space3),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final app = context.appColors;
    final hasLimit = limit != null && limit! > 0;
    final ratio = hasLimit ? spent / limit! : 0.0;
    final over = hasLimit && spent > limit!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(category, style: context.text.bodyLarge, overflow: TextOverflow.ellipsis)),
                if (hasLimit)
                  Text(
                    over ? '${formatRM(spent - limit!, whole: true)} over' : '${formatRM(limit! - spent, whole: true)} left',
                    style: context.text.labelMedium?.copyWith(
                      color: over ? app.expense : (ratio >= 0.9 ? app.warning : colors.onSurfaceVariant),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text('Set limit', style: context.text.labelMedium?.copyWith(color: colors.primary)),
              ],
            ),
            if (hasLimit) ...[
              const SizedBox(height: AppTheme.space2),
              _BudgetBar(ratio: ratio),
              const SizedBox(height: AppTheme.space1),
              Text(
                '${formatRM(spent)} of ${formatRM(limit!, whole: true)}',
                style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ] else if (spent > 0)
              Text('${formatRM(spent)} spent', style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final double ratio;
  const _BudgetBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final color = ratio > 1 ? app.expense : (ratio >= 0.9 ? app.warning : context.colors.primary);
    return LinearProgressIndicator(value: ratio.clamp(0.0, 1.0), color: color);
  }
}
