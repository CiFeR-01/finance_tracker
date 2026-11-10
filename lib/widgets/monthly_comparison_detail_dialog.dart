import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyComparisonDetailDialog extends StatelessWidget {
  final Map<String, double> monthlyIncomes;
  final Map<String, double> monthlyExpenses;
  final List<DateTime> months;

  const MonthlyComparisonDetailDialog({
    super.key,
    required this.monthlyIncomes,
    required this.monthlyExpenses,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    double maxAmount = 1000;
    List<BarChartGroupData> barGroups = [];

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
            BarChartRodData(
              toY: exp,
              color: Colors.red,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: inc,
              color: Colors.green,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    maxAmount = ((maxAmount / 500).ceil() * 500).toDouble();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Yearly Comparison', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scrollable Chart
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 600, // Enough width to spread out the 12 months
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxAmount,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < months.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MMM').format(months[index]),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 500,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Table/List View of the data
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: months.length,
                itemBuilder: (context, index) {
                  String key = DateFormat('MMMM').format(months[index]);
                  double inc = monthlyIncomes[DateFormat('MMM').format(months[index])] ?? 0;
                  double exp = monthlyExpenses[DateFormat('MMM').format(months[index])] ?? 0;
                  double diff = inc - exp;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Text('RM ${inc.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                        ),
                        Expanded(
                          child: Text('RM ${exp.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                        Expanded(
                          child: Text(
                            '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: diff >= 0 ? Colors.blue : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
