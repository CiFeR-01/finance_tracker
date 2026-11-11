import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../viewmodels/tax_view_model.dart';
import '../widgets/page_header.dart';
import '../widgets/tax_estimate_card.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import 'add_expense_page.dart';
import 'add_income_page.dart';

class TaxPage extends StatelessWidget {
  const TaxPage({super.key});

  /// Lets the user pick which kind of record to add, then opens that form.
  void _showAddRecordChooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.south_west_rounded, color: context.appColors.income),
              title: const Text('Add income'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIncomePage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.north_east_rounded, color: context.appColors.expense),
              title: const Text('Add expense'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpensePage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactions(BuildContext context, String title, List<dynamic> transactions) {
    final app = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space5, 0, AppTheme.space5, AppTheme.space3),
              child: Text(title, style: context.text.headlineSmall),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(child: Text('No transactions found', style: context.text.bodyLarge))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        if (tx is IncomeRecord) {
                          double amount = 0;
                          if (title == 'Life Insurance and EPF') amount = tx.epfAmount;
                          if (title == 'SOCSO Contribution') amount = tx.socsoAmount;
                          return ListTile(
                            title: Text(tx.category),
                            subtitle: Text(DateFormat('d MMM yyyy').format(tx.incomeDate)),
                            trailing: Text(formatRM(amount),
                                style: context.text.titleSmall?.copyWith(color: app.income, fontWeight: FontWeight.w700)),
                          );
                        } else if (tx is ExpenseRecord) {
                          return ListTile(
                            title: Text(tx.category),
                            subtitle: Text(DateFormat('d MMM yyyy').format(tx.expenseDate)),
                            trailing: Text(formatRM(tx.amount),
                                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaxViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view tax data.')));
    }

    if (viewModel.userModel == null) {
      return const Scaffold(body: Center(child: Text('User profile not found.')));
    }

    final fixedReliefs = viewModel.userModel!.taxProfile.getFixedReliefItems();
    final fixedTitles = fixedReliefs.map((e) => e['title'] as String).toList();

    bool checkIfFixed(String title) {
      if (fixedTitles.contains(title)) return true;
      if (title.startsWith('Child Relief')) return true;
      if (title.startsWith('Disabled Child')) return true;
      return false;
    }

    final year = DateTime.now().year;
    final header = PageHeader(title: 'Tax', subtitle: 'Reliefs for assessment year $year');

    if (viewModel.hasNoRecords) {
      return Scaffold(
        body: Column(
          children: [
            header,
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: context.colors.outline),
                      const SizedBox(height: AppTheme.space4),
                      Text('No records for $year yet', style: context.text.titleMedium),
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        'Add income and expenses to track your tax reliefs.',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppTheme.space5),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                        onPressed: () => _showAddRecordChooser(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add a record'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final claimedReliefs = viewModel.claimedReliefs;
    final colors = context.colors;
    final app = context.appColors;

    return Scaffold(
      body: Column(
        children: [
          header,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space5),
                  decoration: BoxDecoration(
                    color: app.taxContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total relief claimed', style: context.text.labelLarge?.copyWith(color: app.onTaxContainer)),
                      const SizedBox(height: AppTheme.space1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRM(viewModel.totalReliefClaimed),
                          style: context.text.displaySmall?.copyWith(
                            color: app.onTaxContainer,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (viewModel.estimate != null) ...[
                  const SizedBox(height: AppTheme.space3),
                  TaxEstimateCard(estimate: viewModel.estimate!),
                ],
                const SizedBox(height: AppTheme.space3),
                SectionCard(
                  title: 'Reliefs',
                  child: claimedReliefs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                          child: Center(
                            child: Text('No tax reliefs claimed yet.',
                                style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                          ),
                        )
                      : Column(
                          children: [
                            for (final item in claimedReliefs)
                              Builder(builder: (context) {
                                final title = item['title'] as String;
                                final isFixed = checkIfFixed(title);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  onTap: isFixed
                                      ? null
                                      : () {
                                          final txs = viewModel.getTransactionsForRelief(title);
                                          _showTransactions(context, title, txs);
                                        },
                                  child: _buildReliefItem(context, title, item['amount'], item['limit'], isClickable: !isFixed),
                                );
                              }),
                          ],
                        ),
                ),
                if (viewModel.totalDonations > 0) ...[
                  const SizedBox(height: AppTheme.space3),
                  _buildSimpleInfoCard(
                    context,
                    'Donations & gifts',
                    viewModel.totalDonations,
                    onTap: () {
                      final txs = viewModel.getTransactionsForRelief('Total Donations');
                      _showTransactions(context, 'Donations & gifts', txs);
                    },
                  ),
                ],
                if (viewModel.totalZakat > 0) ...[
                  const SizedBox(height: AppTheme.space3),
                  _buildSimpleInfoCard(
                    context,
                    'Zakat (rebate)',
                    viewModel.totalZakat,
                    isRebate: true,
                    onTap: () {
                      final txs = viewModel.getTransactionsForRelief('Zakat');
                      _showTransactions(context, 'Zakat', txs);
                    },
                  ),
                ],
                const SizedBox(height: AppTheme.space4),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Update your Profile to change fixed relief settings.')),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Adjust fixed reliefs in Profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReliefItem(BuildContext context, String title, double current, double limit, {bool isClickable = false}) {
    final app = context.appColors;
    final colors = context.colors;
    final progress = limit <= 0 ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final isMaxed = progress >= 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space2 + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
              if (isMaxed) ...[
                Icon(Icons.check_circle_rounded, size: 16, color: app.warning),
                const SizedBox(width: AppTheme.space1),
                Text('Limit reached', style: context.text.labelSmall?.copyWith(color: app.warning)),
              ],
              if (isClickable) Icon(Icons.chevron_right_rounded, size: 20, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          LinearProgressIndicator(value: progress, color: isMaxed ? app.warning : colors.primary),
          const SizedBox(height: AppTheme.space1),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${formatRM(current, whole: true)} of ${formatRM(limit, whole: true)}',
              style: context.text.labelMedium?.copyWith(
                color: isMaxed ? app.warning : colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoCard(BuildContext context, String title, double amount, {bool isRebate = false, VoidCallback? onTap}) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space5 - 4, vertical: AppTheme.space1),
        title: Text(title, style: context.text.titleSmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatRM(amount),
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isRebate ? context.appColors.income : context.colors.onSurface,
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
