import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import 'package:intl/intl.dart';

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
    // Group by month
    Map<String, double> monthlyIncomes = {};
    Map<String, double> monthlyExpenses = {};

    // Get last 6 months
    List<DateTime> months = [];
    for (int i = 5; i >= 0; i--) {
      months.add(DateTime(DateTime.now().year, DateTime.now().month - i));
    }

    for (var month in months) {
      String key = DateFormat('MMM').format(month);
      monthlyIncomes[key] = 0;
      monthlyExpenses[key] = 0;
    }

    for (var income in incomes) {
      String key = DateFormat('MMM').format(income.incomeDate);
      if (monthlyIncomes.containsKey(key)) {
        monthlyIncomes[key] = monthlyIncomes[key]! + income.netIncome;
      }
    }

    for (var expense in expenses) {
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
            BarChartRodData(toY: exp, color: Colors.red, width: 10, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: inc, color: Colors.green, width: 10, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      );
    }

    // Round up maxAmount to nearest 250 for grid
    maxAmount = ((maxAmount / 250).ceil() * 250).toDouble();
    if (maxAmount == 0) maxAmount = 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
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
                        if (index >= 0 && index < months.length) {
                          return Text(DateFormat('MMM').format(months[index]), style: const TextStyle(color: Colors.grey, fontSize: 10));
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
                        if (value % 250 == 0 || value == maxAmount) {
                          return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
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
                  horizontalInterval: 250,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Colors.red, label: 'expenses'),
              SizedBox(width: 20),
              _LegendItem(color: Colors.green, label: 'income'),
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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
