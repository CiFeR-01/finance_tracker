import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/summary_card.dart';
import '../widgets/most_spent_card.dart';
import '../widgets/monthly_comparison_card.dart';
import '../widgets/selected_month_detail_chart.dart';
import '../widgets/category_pie_charts.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/page_header.dart';
import '../theme/app_theme.dart';
import '../theme/formatters.dart';
import 'add_page.dart';
import 'tax_page.dart';
import 'profile_page.dart';
import 'report_page.dart';
import 'budgets_page.dart';
import '../viewmodels/home_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const AddPage(),
    const ReportPage(),
    const TaxPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex < _pages.length ? _currentIndex : 0],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final app = context.appColors;
    final colors = context.colors;
    final periodName = DateFormat('MMMM yyyy').format(viewModel.selectedPeriod);
    final spentRatio = viewModel.totalIncome <= 0
        ? 0.0
        : (viewModel.totalExpenses / viewModel.totalIncome).clamp(0.0, 1.0);

    return Column(
      children: [
        PageHeader(
          title: 'Overview',
          subtitle: 'Your money this month',
          actions: [
            PeriodPill<DateTime>(
              value: viewModel.selectedPeriod,
              options: viewModel.availablePeriods,
              label: (p) => DateFormat('MMM yyyy').format(p),
              onChanged: viewModel.setSelectedPeriod,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space5),
            children: [
              // Hero: what's left this month, with how much of income is spent.
              Container(
                padding: const EdgeInsets.all(AppTheme.space5),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Left this month', style: context.text.labelLarge?.copyWith(color: colors.onPrimaryContainer)),
                    const SizedBox(height: AppTheme.space1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRM(viewModel.savings),
                        style: context.text.displaySmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    LinearProgressIndicator(
                      value: spentRatio,
                      color: viewModel.isExpenseHigh ? app.expense : colors.primary,
                      backgroundColor: colors.onPrimaryContainer.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      viewModel.totalIncome <= 0
                          ? 'Add income to see how much you have spent'
                          : '${viewModel.expensePercentage.toStringAsFixed(0)}% of income spent',
                      style: context.text.bodySmall?.copyWith(color: colors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              if (viewModel.isExpenseHigh) ...[
                const SizedBox(height: AppTheme.space3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space3),
                  decoration: BoxDecoration(
                    color: app.warningContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: app.onWarningContainer),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Text(
                          viewModel.budgetAlertMessage,
                          style: context.text.bodyMedium?.copyWith(color: app.onWarningContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.space3),
              SizedBox(
                height: 96,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Income',
                        icon: Icons.south_west_rounded,
                        amount: formatRM(viewModel.totalIncome),
                        backgroundColor: app.incomeContainer,
                        textColor: app.onIncomeContainer,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Expanded(
                      child: SummaryCard(
                        title: 'Spent',
                        icon: Icons.north_east_rounded,
                        amount: formatRM(viewModel.totalExpenses),
                        backgroundColor: app.expenseContainer,
                        textColor: app.onExpenseContainer,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Expanded(
                      child: SummaryCard(
                        title: 'Tax relief',
                        icon: Icons.verified_rounded,
                        amount: formatRM(viewModel.taxReclaimable),
                        backgroundColor: app.taxContainer,
                        textColor: app.onTaxContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              _BudgetsSummary(viewModel: viewModel),
              const SizedBox(height: AppTheme.space3),
              MostSpentCard(
                category: viewModel.mostSpentCategory,
                amount: formatRM(viewModel.mostSpentAmount),
              ),
              const SizedBox(height: AppTheme.space3),
              SelectedMonthDetailChart(
                incomes: viewModel.filteredIncomes,
                expenses: viewModel.filteredExpenses,
                monthName: periodName,
              ),
              const SizedBox(height: AppTheme.space3),
              CategoryPieCharts(
                incomes: viewModel.filteredIncomes,
                expenses: viewModel.filteredExpenses,
                monthName: periodName,
              ),
              const SizedBox(height: AppTheme.space3),
              MonthlyComparisonCard(
                incomes: viewModel.incomes,
                expenses: viewModel.expenses,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Home card: the three budgets closest to their limit, or a prompt to set some.
class _BudgetsSummary extends StatelessWidget {
  final HomeViewModel viewModel;
  const _BudgetsSummary({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsPage()));
    final statuses = viewModel.budgetStatuses;

    if (statuses.isEmpty) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space2),
          leading: CircleAvatar(
            backgroundColor: context.colors.secondaryContainer,
            child: Icon(Icons.savings_outlined, color: context.colors.onSecondaryContainer),
          ),
          title: const Text('Set monthly budgets'),
          subtitle: const Text('Get warned before you overspend in a category'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: open,
        ),
      );
    }

    return SectionCard(
      title: 'Budgets',
      trailing: TextButton(onPressed: open, child: const Text('Manage')),
      padding: const EdgeInsets.fromLTRB(AppTheme.space5 - 4, AppTheme.space3, AppTheme.space2, AppTheme.space3),
      child: Column(
        children: [
          for (final b in statuses.take(3))
            BudgetTile(
              category: b.category,
              limit: b.limit,
              spent: b.spent,
              onTap: open,
              padding: const EdgeInsets.only(right: AppTheme.space3, bottom: AppTheme.space3),
            ),
        ],
      ),
    );
  }
}
