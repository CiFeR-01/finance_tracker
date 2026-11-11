import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One row in a transaction list: category icon, category + date, amount.
class TransactionCard extends StatelessWidget {
  final String amount;
  final String category;
  final String date;
  final Color borderColor;
  final Color amountColor;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final String? taxTag;
  final IconData icon;

  const TransactionCard({
    super.key,
    required this.amount,
    required this.category,
    required this.date,
    required this.borderColor,
    required this.amountColor,
    required this.onDelete,
    this.onTap,
    this.taxTag,
    this.icon = Icons.receipt_long_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space2),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space3, AppTheme.space1, AppTheme.space3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: borderColor.withValues(alpha: 0.14),
                  child: Icon(icon, color: borderColor, size: 22),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(date, style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                          if (taxTag != null) ...[
                            const SizedBox(width: AppTheme.space2),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: context.appColors.taxContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 12, color: context.appColors.onTaxContainer),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        taxTag!,
                                        style: context.text.labelSmall?.copyWith(color: context.appColors.onTaxContainer),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space2),
                Text(
                  amount,
                  style: context.text.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline_rounded, color: colors.onSurfaceVariant),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
