import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Highlights the category with the highest spend this period.
class MostSpentCard extends StatelessWidget {
  final String category;
  final String amount;

  const MostSpentCard({
    super.key,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space3),
              decoration: BoxDecoration(
                color: app.expenseContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(Icons.local_fire_department_rounded, color: app.onExpenseContainer),
            ),
            const SizedBox(width: AppTheme.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Most spent on', style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                  Text(category, style: context.text.titleMedium, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              amount,
              style: context.text.titleMedium?.copyWith(
                color: app.expense,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
