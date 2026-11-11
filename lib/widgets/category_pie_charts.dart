import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense_record.dart';
import '../models/income_record.dart';
import 'category_detail_dialog.dart';
import 'page_header.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';

class CategoryPieCharts extends StatelessWidget {
  final List<IncomeRecord> incomes;
  final List<ExpenseRecord> expenses;
  final String monthName;

  const CategoryPieCharts({
    super.key,
    required this.incomes,
    required this.expenses,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPieChartCard(
          context: context,
          title: 'Income by category',
          data: _groupIncomes(incomes),
          emptyMessage: 'No income recorded.',
        ),
        const SizedBox(height: AppTheme.space3),
        _buildPieChartCard(
          context: context,
          title: 'Spending by category',
          data: _groupExpenses(expenses),
          emptyMessage: 'No expenses recorded.',
        ),
      ],
    );
  }

  Map<String, double> _groupIncomes(List<IncomeRecord> list) {
    Map<String, double> map = {};
    for (var item in list) {
      map[item.category] = (map[item.category] ?? 0) + item.netIncome;
    }
    return map;
  }

  Map<String, double> _groupExpenses(List<ExpenseRecord> list) {
    Map<String, double> map = {};
    for (var item in list) {
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }
    return map;
  }

  Widget _buildPieChartCard({
    required BuildContext context,
    required String title,
    required Map<String, double> data,
    required String emptyMessage,
  }) {
    final bool isEmpty = data.isEmpty;
    final palette = context.appColors.chartPalette;
    final colors = context.colors;
    Color colorFor(int i) => palette[i % palette.length];
    final entries = data.entries.toList();

    return SectionCard(
      title: title,
      trailing: isEmpty
          ? Text(monthName, style: context.text.labelMedium?.copyWith(color: colors.onSurfaceVariant))
          : Icon(Icons.open_in_full_rounded, color: colors.onSurfaceVariant, size: 18),
      onTap: isEmpty
          ? null
          : () {
              showDialog(
                context: context,
                builder: (context) => CategoryDetailDialog(
                  title: '$title · $monthName',
                  data: data,
                  palette: palette,
                ),
              );
            },
      child: isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
              child: Center(
                child: Text(emptyMessage, style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              ),
            )
          : Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        for (var i = 0; i < entries.length; i++)
                          PieChartSectionData(color: colorFor(i), value: entries[i].value, title: '', radius: 22),
                      ],
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < entries.length && i < 4; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: colorFor(i), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: AppTheme.space2),
                              Expanded(
                                child: Text(entries[i].key, style: context.text.bodySmall, overflow: TextOverflow.ellipsis),
                              ),
                              Text(
                                formatRM(entries[i].value, whole: true),
                                style: context.text.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                            ],
                          ),
                        ),
                      if (entries.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: AppTheme.space1),
                          child: Text(
                            '+${entries.length - 4} more',
                            style: context.text.labelMedium?.copyWith(color: colors.primary),
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
