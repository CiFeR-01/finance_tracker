import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense_record.dart';
import '../models/income_record.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import 'page_header.dart';

/// Income vs expenses for one month, as two bars plus a short summary.
class SelectedMonthDetailChart extends StatelessWidget {
  final List<IncomeRecord> incomes;
  final List<ExpenseRecord> expenses;
  final String monthName;

  const SelectedMonthDetailChart({
    super.key,
    required this.incomes,
    required this.expenses,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final colors = context.colors;
    final double totalIncome = incomes.fold(0, (sum, item) => sum + item.netIncome);
    final double totalExpenses = expenses.fold(0, (sum, item) => sum + item.amount);
    final double balance = totalIncome - totalExpenses;

    double maxY = (totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2;
    if (maxY == 0) maxY = 1000;

    BarChartGroupData bar(int x, double y, Color c) => BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: y,
              color: c,
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: colors.surfaceContainerHighest),
            ),
          ],
        );

    return SectionCard(
      title: 'Income vs expenses',
      trailing: Text(monthName, style: context.text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [bar(0, totalIncome, app.income), bar(1, totalExpenses, app.expense)],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space5),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem(context, app.income, 'Income', formatRM(totalIncome)),
                const SizedBox(height: AppTheme.space3),
                _legendItem(context, app.expense, 'Expenses', formatRM(totalExpenses)),
                const Padding(padding: EdgeInsets.symmetric(vertical: AppTheme.space3), child: Divider()),
                Text(
                  balance >= 0 ? 'Net savings' : 'Net deficit',
                  style: context.text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                Text(
                  formatRM(balance.abs()),
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: balance >= 0 ? app.savings : app.expense,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label, String amount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
              Text(amount, style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ],
    );
  }
}
