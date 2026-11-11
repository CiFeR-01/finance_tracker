import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/page_header.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import 'add_income_page.dart';
import 'add_expense_page.dart';
import 'recurring_page.dart';
import '../viewmodels/home_view_model.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import 'package:intl/intl.dart';

/// The Transactions tab: income and expense lists for the selected month,
/// with search, details, delete-with-undo and an add menu.
class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showDetailsSheet(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required Widget Function() editPage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(AppTheme.space5, 0, AppTheme.space5, AppTheme.space6),
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: context.text.headlineSmall)),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(this.context, MaterialPageRoute(builder: (_) => editPage()));
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _proofImage(BuildContext context, String label, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.space5),
        Text(label, style: context.text.titleSmall),
        const SizedBox(height: AppTheme.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Text('Image not found', style: context.text.bodyMedium),
          ),
        ),
      ],
    );
  }

  void _showIncomeDetails(BuildContext context, IncomeRecord income) {
    final app = context.appColors;
    _showDetailsSheet(context, title: 'Income details', editPage: () => AddIncomePage(existing: income), children: [
      _buildDetailRow(context, 'Gross income', formatRM(income.totalIncome)),
      _buildDetailRow(context, 'EPF', formatRM(income.epfAmount)),
      _buildDetailRow(context, 'SOCSO', formatRM(income.socsoAmount)),
      _buildDetailRow(context, 'PCB', formatRM(income.pcbAmount)),
      const Padding(padding: EdgeInsets.symmetric(vertical: AppTheme.space2), child: Divider()),
      _buildDetailRow(context, 'Net income', formatRM(income.netIncome), isBold: true, color: app.income),
      _buildDetailRow(context, 'Category', income.category),
      _buildDetailRow(context, 'Date', DateFormat('d MMMM yyyy').format(income.incomeDate)),
      if (income.description != null && income.description!.isNotEmpty)
        _buildDetailRow(context, 'Description', income.description!),
      if (income.proofImagePath != null) _proofImage(context, 'Proof of income', income.proofImagePath!),
    ]);
  }

  void _showExpenseDetails(BuildContext context, ExpenseRecord expense) {
    final app = context.appColors;
    _showDetailsSheet(context, title: 'Expense details', editPage: () => AddExpensePage(existing: expense), children: [
      _buildDetailRow(context, 'Amount', formatRM(expense.amount), isBold: true, color: app.expense),
      _buildDetailRow(context, 'Category', expense.category),
      _buildDetailRow(context, 'Date', DateFormat('d MMMM yyyy').format(expense.expenseDate)),
      _buildDetailRow(context, 'Tax deductible', expense.isTaxDeductible ? 'Yes' : 'No'),
      if (expense.description != null && expense.description!.isNotEmpty)
        _buildDetailRow(context, 'Description', expense.description!),
      if (expense.proofImagePath != null) _proofImage(context, 'Proof of expense', expense.proofImagePath!),
    ]);
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.text.bodyLarge?.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final app = context.appColors;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: 'Activity',
            actions: [
              PeriodPill<DateTime>(
                value: viewModel.selectedPeriod,
                options: viewModel.availablePeriods,
                label: (p) => DateFormat('MMM yyyy').format(p),
                onChanged: viewModel.setSelectedPeriod,
              ),
              IconButton(
                tooltip: 'Recurring',
                icon: const Icon(Icons.event_repeat_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringPage())),
              ),
              PopupMenuButton<String>(
                tooltip: 'Add transaction',
                offset: const Offset(0, 52),
                onSelected: (value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => value == 'income' ? const AddIncomePage() : const AddExpensePage(),
                    ),
                  );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'income',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.south_west_rounded, color: app.income),
                      title: const Text('Add income'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'expense',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.north_east_rounded, color: app.expense),
                      title: const Text('Add expense'),
                    ),
                  ),
                ],
                child: IgnorePointer(
                  child: IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              ),
            ],
            bottom: Column(
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search transactions',
                  leading: const Icon(Icons.search_rounded),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(context.colors.surfaceContainerHigh),
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppTheme.space4)),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: AppTheme.space3),
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(AppTheme.space1),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Income'),
                      Tab(text: 'Expenses'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildIncomeTab(viewModel), _buildExpenseTab(viewModel)],
            ),
          ),
        ],
      ),
    );
  }

  /// Deletes a record right away and offers a few seconds to undo it.
  Future<void> _deleteWithUndo({
    required String label,
    required Future<void> Function() delete,
    required Future<void> Function() restore,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await delete();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$label deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await restore();
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Could not restore: $e')));
            }
          },
        ),
      ),
    );
  }

  Widget _buildIncomeTab(HomeViewModel viewModel) {
    final app = context.appColors;
    final filtered = viewModel.filteredIncomes
        .where(
          (i) =>
              i.category.toLowerCase().contains(_searchQuery) ||
              (i.description?.toLowerCase().contains(_searchQuery) ?? false),
        )
        .toList();

    final total = filtered.fold(0.0, (sum, i) => sum + i.netIncome);

    return _buildListContent(
      items: filtered,
      total: total,
      color: app.income,
      icon: Icons.account_balance_wallet_outlined,
      emptyMessage: 'No income this month',
      itemBuilder: (income) => TransactionCard(
        amount: formatRM(income.netIncome, signed: true),
        category: income.category,
        date: DateFormat('d MMM').format(income.incomeDate),
        borderColor: app.income,
        amountColor: app.income,
        icon: Icons.south_west_rounded,
        onDelete: () => _deleteWithUndo(
          label: 'Income',
          delete: () => viewModel.deleteIncome(income.id),
          restore: () => viewModel.restoreIncome(income),
        ),
        onTap: () => _showIncomeDetails(context, income),
      ),
    );
  }

  Widget _buildExpenseTab(HomeViewModel viewModel) {
    final app = context.appColors;
    final filtered = viewModel.filteredExpenses
        .where(
          (e) =>
              e.category.toLowerCase().contains(_searchQuery) ||
              (e.description?.toLowerCase().contains(_searchQuery) ?? false),
        )
        .toList();

    final total = filtered.fold(0.0, (sum, e) => sum + e.amount);

    return _buildListContent(
      items: filtered,
      total: total,
      color: app.expense,
      icon: Icons.shopping_bag_outlined,
      emptyMessage: 'No expenses this month',
      itemBuilder: (expense) => TransactionCard(
        amount: formatRM(-expense.amount),
        category: expense.category,
        date: DateFormat('d MMM').format(expense.expenseDate),
        borderColor: app.expense,
        amountColor: context.colors.onSurface,
        icon: Icons.north_east_rounded,
        taxTag: expense.isTaxDeductible ? 'Tax relief' : null,
        onDelete: () => _deleteWithUndo(
          label: 'Expense',
          delete: () => viewModel.deleteExpense(expense.id),
          restore: () => viewModel.restoreExpense(expense),
        ),
        onTap: () => _showExpenseDetails(context, expense),
      ),
    );
  }

  Widget _buildListContent({
    required List<dynamic> items,
    required double total,
    required Color color,
    required IconData icon,
    required String emptyMessage,
    required Widget Function(dynamic) itemBuilder,
  }) {
    final colors = context.colors;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: colors.outline),
            const SizedBox(height: AppTheme.space4),
            Text(emptyMessage, style: context.text.titleMedium?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }

    final Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      final DateTime date = item is IncomeRecord ? item.incomeDate : (item as ExpenseRecord).expenseDate;
      final String key = DateFormat('EEEE, d MMMM').format(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final List<String> sortedKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
      itemCount: grouped.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space2),
            child: Row(
              children: [
                Text('Total this month', style: context.text.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
                const Spacer(),
                Text(
                  formatRM(total),
                  style: context.text.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }
        final String dateKey = sortedKeys[index - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space1, AppTheme.space3, 0, AppTheme.space2),
              child: Text(dateKey, style: context.text.labelLarge?.copyWith(color: colors.primary)),
            ),
            ...grouped[dateKey]!.map((item) => itemBuilder(item)),
          ],
        );
      },
    );
  }
}
