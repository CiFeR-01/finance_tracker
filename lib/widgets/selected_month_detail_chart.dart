import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense_record.dart';
import '../models/income_record.dart';

/// A widget that displays a detailed comparison of Income vs Expenses for a specific month.
/// 
/// It uses a Bar Chart to show the total income and total expenses side-by-side,
/// and provides a visual breakdown of the net balance.
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
    final double totalIncome = incomes.fold(0, (sum, item) => sum + item.netIncome);
    final double totalExpenses = expenses.fold(0, (sum, item) => sum + item.amount);
    final double balance = totalIncome - totalExpenses;

    // Determine the max Y value for the chart to scale properly
    double maxY = (totalIncome > totalExpenses ? totalIncome : totalExpenses);
    maxY = (maxY * 1.2); // Add 20% padding at the top
    if (maxY == 0) maxY = 1000;

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
          Text(
            'Analysis for $monthName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // 1. Comparison Bar Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: const FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: totalIncome,
                              color: Colors.green,
                              width: 25,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: totalExpenses,
                              color: Colors.red,
                              width: 25,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // 2. Summary details on the right
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      color: Colors.green,
                      label: 'Total Income',
                      amount: 'RM ${totalIncome.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      color: Colors.red,
                      label: 'Total Expenses',
                      amount: 'RM ${totalExpenses.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    Text(
                      balance >= 0 ? 'Net Savings' : 'Net Deficit',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'RM ${balance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.blue : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label, required String amount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: Text(
            amount,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
