import 'package:flutter/material.dart';
import '../models/tax_rates.dart';
import '../services/tax_estimator.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import 'page_header.dart';

/// "You'll get about RM 820 back" card on the Tax tab, with a breakdown.
class TaxEstimateCard extends StatefulWidget {
  final TaxEstimate estimate;

  const TaxEstimateCard({super.key, required this.estimate});

  @override
  State<TaxEstimateCard> createState() => _TaxEstimateCardState();
}

class _TaxEstimateCardState extends State<TaxEstimateCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.estimate;
    final app = context.appColors;
    final colors = context.colors;
    final amount = e.balance.abs();
    final even = amount < 50;

    final String headline;
    final Color tone;
    if (even) {
      headline = 'About even';
      tone = colors.onSurface;
    } else if (e.isRefund) {
      headline = 'About ${formatRM(amount, whole: true)} back';
      tone = app.income;
    } else {
      headline = 'About ${formatRM(amount, whole: true)} to pay';
      tone = app.expense;
    }

    final subtitle = even
        ? 'Your PCB roughly matches the tax on your income.'
        : e.isRefund
            ? 'Your PCB is more than the tax you owe.'
            : 'Your PCB is less than the tax you owe.';

    final year = e.rates.year;
    final staleRates = TaxRates.isBeyondKnown(year);

    return SectionCard(
      title: 'Tax estimate',
      trailing: Text('YA $year', style: context.text.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: context.text.headlineSmall?.copyWith(color: tone)),
          const SizedBox(height: AppTheme.space1),
          Text(subtitle, style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          if (e.isProjected) ...[
            const SizedBox(height: AppTheme.space2),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: AppTheme.space1),
                Expanded(
                  child: Text(
                    'Assumes your salary continues for ${e.projectedMonths} more month${e.projectedMonths == 1 ? '' : 's'}.',
                    style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          if (staleRates) ...[
            const SizedBox(height: AppTheme.space3),
            Container(
              padding: const EdgeInsets.all(AppTheme.space3),
              decoration: BoxDecoration(
                color: app.warningContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                'Using YA ${TaxRates.latestKnownYear} rates. $year rates may differ.',
                style: context.text.bodySmall?.copyWith(color: app.onWarningContainer),
              ),
            ),
          ],
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: AppTheme.space3),
              child: Text('Tap for the breakdown',
                  style: context.text.labelMedium?.copyWith(color: colors.primary)),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppTheme.space4),
              child: Column(
                children: [
                  _row(context, e.isProjected ? 'Income (projected)' : 'Income', e.gross),
                  _row(context, 'Reliefs', -e.reliefs),
                  if (e.donationDeduction > 0) _row(context, 'Donations', -e.donationDeduction),
                  _row(context, 'Chargeable income', e.chargeable, bold: true),
                  const Padding(padding: EdgeInsets.symmetric(vertical: AppTheme.space2), child: Divider()),
                  _row(context, 'Tax', e.taxBeforeRebates),
                  if (e.rebates > 0) _row(context, 'Rebates (incl. zakat)', -e.rebates),
                  _row(context, 'Tax payable', e.taxPayable, bold: true),
                  _row(context, e.isProjected ? 'PCB (projected)' : 'PCB paid', -e.pcbPaid),
                  const SizedBox(height: AppTheme.space3),
                  Text(
                    'An estimate from your records and LHDN resident rates. '
                    'Your e-Filing result is the final figure.',
                    style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value, {bool bold = false}) {
    final style = (bold ? context.text.titleSmall : context.text.bodyMedium)
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style?.copyWith(color: bold ? null : context.colors.onSurfaceVariant))),
          Text(formatRM(value), style: style),
        ],
      ),
    );
  }
}
