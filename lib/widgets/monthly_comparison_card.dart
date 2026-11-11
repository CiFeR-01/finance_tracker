import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'page_header.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import 'package:intl/intl.dart';
import 'monthly_comparison_detail_dialog.dart';

class MonthlyComparisonCard extends StatelessWidget {
  final List<IncomeRecord> incomes;
  final List<ExpenseRecord> expenses;

  const MonthlyComparisonCard({
    super.key,
    required this.incomes,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final colors = context.colors;
    final axisStyle = context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant);
    // Group by month
    Map<String, double> monthlyIncomes = {};
    Map<String, double> monthlyExpenses = {};

    // Get all months of the current year
    List<DateTime> months = [];
    int currentYear = DateTime.now().year;
    for (int i = 1; i <= 12; i++) {
      months.add(DateTime(currentYear, i));
    }

    for (var month in months) {
      String key = DateFormat('MMM').format(month);
      monthlyIncomes[key] = 0;
      monthlyExpenses[key] = 0;
    }

    for (var income in incomes) {
      // Only this year's records belong in this chart; keys are month names.
      if (income.incomeDate.year != currentYear) continue;
      String key = DateFormat('MMM').format(income.incomeDate);
      if (monthlyIncomes.containsKey(key)) {
        monthlyIncomes[key] = monthlyIncomes[key]! + income.netIncome;
      }
    }

    for (var expense in expenses) {
      if (expense.expenseDate.year != currentYear) continue;
      String key = DateFormat('MMM').format(expense.expenseDate);
      if (monthlyExpenses.containsKey(key)) {
        monthlyExpenses[key] = monthlyExpenses[key]! + expense.amount;
      }
    }

    List<BarChartGroupData> barGroups = [];
    double maxAmount = 1000;

    for (int i = 0; i < months.length; i++) {
      String key = DateFormat('MMM').format(months[i]);
      double inc = monthlyIncomes[key] ?? 0;
      double exp = monthlyExpenses[key] ?? 0;

      if (inc > maxAmount) maxAmount = inc;
      if (exp > maxAmount) maxAmount = exp;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: exp, color: app.expense, width: 6, borderRadius: BorderRadius.circular(3)),
            BarChartRodData(toY: inc, color: app.income, width: 6, borderRadius: BorderRadius.circular(3)),
          ],
        ),
      );
    }

    // Pick a round grid step giving about four gridlines, then round the top up to it.
    final rawStep = maxAmount / 4;
    final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final step = [1, 2, 2.5, 5, 10].map((m) => m * magnitude).firstWhere((v) => v >= rawStep);
    maxAmount = (maxAmount / step).ceil() * step;

    return SectionCard(
      title: 'This year by month',
      trailing: Icon(Icons.open_in_full_rounded, color: colors.onSurfaceVariant, size: 18),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => MonthlyComparisonDetailDialog(
            monthlyIncomes: monthlyIncomes,
            monthlyExpenses: monthlyExpenses,
            months: months,
          ),
        );
      },
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxAmount,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          // Show only every 2nd month to prevent overlap in the preview
                          if (index >= 0 && index < months.length && index % 2 == 0) {
                            return Text(DateFormat('MMM').format(months[index]),
                                style: axisStyle);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % step == 0) {
                            return Text(NumberFormat.compact().format(value),
                                style: axisStyle);
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: app.expense, label: 'Expenses'),
                const SizedBox(width: AppTheme.space5),
                _LegendItem(color: app.income, label: 'Income'),
              ],
            ),
          ],
        ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppTheme.space1 + 2),
        Text(
          label,
          style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
