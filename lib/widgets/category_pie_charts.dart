import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense_record.dart';
import '../models/income_record.dart';

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
          title: 'Income Categories - $monthName',
          data: _groupIncomes(incomes),
          baseColor: Colors.green,
          emptyMessage: 'No income recorded.',
        ),
        const SizedBox(height: 20),
        _buildPieChartCard(
          title: 'Expense Categories - $monthName',
          data: _groupExpenses(expenses),
          baseColor: Colors.red,
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
    required String title,
    required Map<String, double> data,
    required Color baseColor,
    required String emptyMessage,
  }) {
    final bool isEmpty = data.isEmpty;

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
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sections: _generateSections(data, baseColor),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getColorForIndex(data.keys.toList().indexOf(entry.key), baseColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${entry.key}: RM${entry.value.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(Map<String, double> data, Color baseColor) {
    List<PieChartSectionData> sections = [];
    int index = 0;
    data.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: _getColorForIndex(index, baseColor),
          value: amount,
          title: '', // Titles can be crowded, using legend instead
          radius: 40,
        ),
      );
      index++;
    });
    return sections;
  }

  Color _getColorForIndex(int index, Color baseColor) {
    // A distinct palette with high contrast colors
    final List<Color> distinctPalette = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.teal,
      Colors.brown,
      Colors.deepPurple,
    ];

    return distinctPalette[index % distinctPalette.length];
  }
}
