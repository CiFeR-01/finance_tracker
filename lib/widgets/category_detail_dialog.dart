import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';

/// A dialog that shows a detailed view of categories with full names and amounts.
/// 
/// This solves the issue of text being cut off in the main view by providing
/// a dedicated, scrollable space for all category information.
class CategoryDetailDialog extends StatelessWidget {
  final String title;
  final Map<String, double> data;
  final List<Color> palette;

  const CategoryDetailDialog({
    super.key,
    required this.title,
    required this.data,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    double total = data.values.fold(0, (sum, val) => sum + val);

    return AlertDialog(
      title: Text(title, style: context.text.titleLarge),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Larger Pie Chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generateSections(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 56,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            // Full List of Categories (Scrollable)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: data.length,
                itemBuilder: (context, index) {
                  String key = data.keys.elementAt(index);
                  double value = data.values.elementAt(index);
                  double percentage = total > 0 ? (value / total) * 100 : 0;
                  Color color = palette[index % palette.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                key,
                                style: context.text.titleSmall,
                                softWrap: true,
                              ),
                              Text(
                                '${formatRM(value)} (${percentage.toStringAsFixed(1)}%)',
                                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                            ],
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections() {
    return List.generate(data.length, (index) {
      double value = data.values.elementAt(index);
      return PieChartSectionData(
        color: palette[index % palette.length],
        value: value,
        title: '',
        radius: 32,
      );
    });
  }
}
