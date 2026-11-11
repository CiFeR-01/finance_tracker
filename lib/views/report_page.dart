import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import '../services/pdf_service.dart';
import '../services/csv_export.dart';
import '../services/receipt_archive.dart';
import '../widgets/page_header.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../models/categories.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _selectedPeriod = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedCategory = 'All Categories';
  _CsvRange _csvRange = _CsvRange.month;

  Future<void> _exportCsv(HomeViewModel vm) async {
    final p = _selectedPeriod;
    bool inRange(DateTime d) => switch (_csvRange) {
          _CsvRange.month => d.year == p.year && d.month == p.month,
          _CsvRange.year => d.year == p.year,
          _CsvRange.all => true,
        };
    final incomes = vm.incomes.where((i) => inRange(i.incomeDate)).toList();
    final expenses = vm.expenses.where((e) => inRange(e.expenseDate)).toList();
    if (incomes.isEmpty && expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions in that range.')));
      return;
    }
    final label = switch (_csvRange) {
      _CsvRange.month => DateFormat('yyyy-MM').format(p),
      _CsvRange.year => '${p.year}',
      _CsvRange.all => 'all',
    };
    try {
      await CsvExport.share(incomes: incomes, expenses: expenses, fileLabel: label);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportReceipts(HomeViewModel vm, int year, bool empty) async {
    final messenger = ScaffoldMessenger.of(context);
    if (empty) {
      messenger.showSnackBar(SnackBar(content: Text('No tax-relief expenses in $year yet.')));
      return;
    }
    try {
      final missing = await ReceiptArchive.share(year: year, expenses: vm.expenses, incomes: vm.incomes);
      if (missing > 0) {
        messenger.showSnackBar(SnackBar(
          content: Text('$missing record${missing == 1 ? ' has' : 's have'} no receipt photo. They are marked MISSING in index.csv.'),
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  final List<String> _categories = ['All Categories', ...expenseCategories];

  void _generateMonthlyReport(List<IncomeRecord> filteredIncomes, List<ExpenseRecord> filteredExpenses) async {
    try {
      if (filteredIncomes.isEmpty && filteredExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Transaction Records available for the selected month.')),
        );
        return;
      }

      // Show a "loading" snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing PDF...'), duration: Duration(seconds: 1)),
      );

      await PdfService.generateMonthlyReport(
        month: _selectedPeriod.month,
        year: _selectedPeriod.year,
        incomes: filteredIncomes,
        expenses: filteredExpenses,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  void _generateCategoryReport(List<ExpenseRecord> filteredExpenses) async {
    try {
      if (filteredExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No expenses available for $_selectedCategory in the selected month.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing PDF...'), duration: Duration(seconds: 1)),
      );

      await PdfService.generateCategoryReport(
        month: _selectedPeriod.month,
        year: _selectedPeriod.year,
        category: _selectedCategory,
        expenses: filteredExpenses,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    // Calculate data for the selected month
    final filteredIncomes = viewModel.incomes.where((i) => i.incomeDate.year == _selectedPeriod.year && i.incomeDate.month == _selectedPeriod.month).toList();
    final filteredExpenses = viewModel.expenses.where((e) => e.expenseDate.year == _selectedPeriod.year && e.expenseDate.month == _selectedPeriod.month).toList();
    
    final totalIn = filteredIncomes.fold(0.0, (sum, i) => sum + i.netIncome);
    final totalEx = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final balance = totalIn - totalEx;

    // Filtered expenses for category report
    final categoryExpenses = _selectedCategory == 'All Categories' 
        ? filteredExpenses 
        : filteredExpenses.where((e) => e.category == _selectedCategory).toList();

    // Past month comparison data
    final prevPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month - 1);
    final prevMonth = prevPeriod.month;
    final prevYear = prevPeriod.year;
    
    final prevIncomes = viewModel.incomes.where((i) => i.incomeDate.month == prevMonth && i.incomeDate.year == prevYear).toList();
    final prevExpenses = viewModel.expenses.where((e) => e.expenseDate.month == prevMonth && e.expenseDate.year == prevYear).toList();
    
    final prevTotalIn = prevIncomes.fold(0.0, (sum, i) => sum + i.netIncome);
    final prevTotalEx = prevExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final prevBalance = prevTotalIn - prevTotalEx;

    final colors = context.colors;
    final app = context.appColors;
    final currentMonthName = DateFormat('MMMM').format(_selectedPeriod);
    final prevMonthName = DateFormat('MMMM').format(DateTime(prevYear, prevMonth));

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Reports',
            subtitle: 'PDF summaries for tax filing',
            actions: [
              PeriodPill<DateTime>(
                value: _selectedPeriod,
                options: viewModel.availablePeriods,
                label: (p) => DateFormat('MMM yyyy').format(p),
                onChanged: (p) => setState(() => _selectedPeriod = p),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
              children: [
                _buildSummaryPreview(totalIn, totalEx, balance),
                const SizedBox(height: AppTheme.space5),
                Text('Report types', style: context.text.titleMedium),
                const SizedBox(height: AppTheme.space3),

                // Complete monthly report
                _reportCard(
                  icon: Icons.summarize_outlined,
                  title: 'Monthly report',
                  description: 'All income, expenses, category breakdown and transaction details for $currentMonthName.',
                  stats: [
                    _buildMiniStat(Icons.south_west_rounded, '${filteredIncomes.length} income'),
                    _buildMiniStat(Icons.north_east_rounded, '${filteredExpenses.length} expenses'),
                  ],
                  buttonLabel: 'Generate monthly PDF',
                  onPressed: () => _generateMonthlyReport(filteredIncomes, filteredExpenses),
                ),
                const SizedBox(height: AppTheme.space3),

                // Category-specific report
                _reportCard(
                  icon: Icons.category_outlined,
                  title: 'Category report',
                  description: 'Expenses in one category with attached receipts.',
                  extra: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                  stats: [_buildMiniStat(Icons.receipt_long_outlined, '${categoryExpenses.length} transactions found')],
                  buttonLabel: 'Generate category PDF',
                  onPressed: () => _generateCategoryReport(categoryExpenses),
                ),
                const SizedBox(height: AppTheme.space3),

                // Spreadsheet export
                _reportCard(
                  icon: Icons.table_view_outlined,
                  title: 'Spreadsheet (CSV)',
                  description: 'Every transaction as rows you can open in Excel or Google Sheets.',
                  extra: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_CsvRange>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: _CsvRange.month, label: Text(DateFormat('MMM').format(_selectedPeriod))),
                        ButtonSegment(value: _CsvRange.year, label: Text('${_selectedPeriod.year}')),
                        const ButtonSegment(value: _CsvRange.all, label: Text('All time')),
                      ],
                      selected: {_csvRange},
                      onSelectionChanged: (v) => setState(() => _csvRange = v.first),
                    ),
                  ),
                  stats: const [],
                  buttonLabel: 'Export CSV',
                  buttonIcon: Icons.ios_share_rounded,
                  onPressed: () => _exportCsv(viewModel),
                ),
                const SizedBox(height: AppTheme.space3),

                // Receipts bundle for LHDN
                Builder(builder: (context) {
                  final year = _selectedPeriod.year;
                  final entries = ReceiptArchive.plan(year: year, expenses: viewModel.expenses, incomes: viewModel.incomes);
                  final withPhoto = entries.where((e) => e.hasReceipt).length;
                  return _reportCard(
                    icon: Icons.folder_zip_outlined,
                    title: 'Tax receipts $year',
                    description: 'Every tax-relief receipt for $year in one zip, sorted into a folder per relief, '
                        'with an index. Keep it for 7 years in case LHDN asks.',
                    stats: [
                      _buildMiniStat(Icons.image_outlined, '$withPhoto receipt${withPhoto == 1 ? '' : 's'}'),
                      if (entries.length > withPhoto)
                        _buildMiniStat(Icons.report_gmailerrorred_outlined, '${entries.length - withPhoto} missing'),
                    ],
                    buttonLabel: 'Export zip',
                    buttonIcon: Icons.ios_share_rounded,
                    onPressed: () => _exportReceipts(viewModel, year, entries.isEmpty),
                  );
                }),
                const SizedBox(height: AppTheme.space5),

                Text('Compared with last month', style: context.text.titleMedium),
                const SizedBox(height: AppTheme.space1),
                Text(
                  '$currentMonthName vs $prevMonthName',
                  style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.space3),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space4),
                    child: Column(
                      children: [
                        _buildComparisonRow('Income', totalIn, prevTotalIn, app.income, prevMonthName),
                        const Padding(padding: EdgeInsets.symmetric(vertical: AppTheme.space3), child: Divider()),
                        _buildComparisonRow('Expenses', totalEx, prevTotalEx, app.expense, prevMonthName, lowerIsBetter: true),
                        const Padding(padding: EdgeInsets.symmetric(vertical: AppTheme.space3), child: Divider()),
                        _buildComparisonRow('Net savings', balance, prevBalance, app.savings, prevMonthName),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.onSurfaceVariant, size: 16),
                    const SizedBox(width: AppTheme.space2),
                    Flexible(
                      child: Text(
                        'Reports are saved to your device Downloads folder',
                        style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> stats,
    required String buttonLabel,
    required VoidCallback onPressed,
    Widget? extra,
    IconData buttonIcon = Icons.picture_as_pdf_outlined,
  }) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space2 + 2),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(icon, color: colors.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(child: Text(title, style: context.text.titleMedium)),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            Text(description, style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
            if (extra != null) ...[
              const SizedBox(height: AppTheme.space4),
              extra,
            ],
            if (stats.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space3),
              Wrap(spacing: AppTheme.space4, runSpacing: AppTheme.space2, children: stats),
            ],
            const SizedBox(height: AppTheme.space4),
            FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String title, double current, double prev, Color color, String prevMonth,
      {bool lowerIsBetter = false}) {
    final app = context.appColors;
    final colors = context.colors;
    final diff = current - prev;
    final isIncrease = diff >= 0;
    final isGood = lowerIsBetter ? !isIncrease : isIncrease;
    final trendColor = diff == 0 ? colors.onSurfaceVariant : (isGood ? app.income : app.expense);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              const SizedBox(height: 2),
              Text(
                '$prevMonth: ${formatRM(prev)}',
                style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatRM(current),
              style: context.text.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 16, color: trendColor),
                const SizedBox(width: AppTheme.space1),
                Text(
                  '${formatRM(diff.abs())} ${isIncrease ? 'more' : 'less'}',
                  style: context.text.labelSmall?.copyWith(color: trendColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryPreview(double income, double expense, double balance) {
    final app = context.appColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _buildSummaryItem('Income', income, app.income)),
              const VerticalDivider(width: 1),
              Expanded(child: _buildSummaryItem('Expenses', expense, app.expense)),
              const VerticalDivider(width: 1),
              Expanded(child: _buildSummaryItem('Balance', balance, balance >= 0 ? app.savings : app.warning)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        const SizedBox(height: AppTheme.space1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRM(amount),
              style: context.text.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    final c = context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: AppTheme.space1),
        Flexible(
          child: Text(text, style: context.text.labelMedium?.copyWith(color: c), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

enum _CsvRange { month, year, all }
