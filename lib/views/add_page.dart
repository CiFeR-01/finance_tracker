import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/transaction_card.dart';
import 'add_income_page.dart';
import 'add_expense_page.dart';
import '../viewmodels/home_view_model.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import 'package:intl/intl.dart';

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

  void _showIncomeDetails(BuildContext context, IncomeRecord income) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Income Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow(
                'Amount',
                'RM ${income.totalIncome.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'EPF',
                'RM ${income.epfAmount.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Socso',
                'RM ${income.socsoAmount.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'PCB',
                'RM ${income.pcbAmount.toStringAsFixed(2)}',
              ),
              const Divider(height: 32),
              _buildDetailRow(
                'Net Income',
                'RM ${income.netIncome.toStringAsFixed(2)}',
                isBold: true,
                color: Colors.green,
              ),
              _buildDetailRow('Category', income.category),
              _buildDetailRow(
                'Date',
                DateFormat('dd MMMM yyyy').format(income.incomeDate),
              ),
              if (income.description != null && income.description!.isNotEmpty)
                _buildDetailRow('Description', income.description!),
              if (income.proofImagePath != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Proof of Income',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(income.proofImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Text('Image not found'),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, ExpenseRecord expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow(
                'Amount',
                'RM ${expense.amount.toStringAsFixed(2)}',
                isBold: true,
                color: Colors.red,
              ),
              _buildDetailRow('Category', expense.category),
              _buildDetailRow(
                'Date',
                DateFormat('dd MMMM yyyy').format(expense.expenseDate),
              ),
              _buildDetailRow(
                'Tax Deductible',
                expense.isTaxDeductible ? 'Yes' : 'No',
              ),
              if (expense.description != null &&
                  expense.description!.isNotEmpty)
                _buildDetailRow('Description', expense.description!),
              if (expense.proofImagePath != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Proof of Expense',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(expense.proofImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Text('Image not found'),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<int>(
                        value: viewModel.selectedMonth,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFFE1BEE7),
                        ),
                        underline: Container(),
                        dropdownColor: const Color(0xFF7B1FA2),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            viewModel.setSelectedMonth(newValue);
                          }
                        },
                        items: List.generate(12, (index) => index + 1).map((
                          int month,
                        ) {
                          final isSelected = month == viewModel.selectedMonth;
                          return DropdownMenuItem<int>(
                            value: month,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(2024, month)),
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFE1BEE7)
                                    : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Text(
                        'Transactions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        onSelected: (value) {
                          if (value == 'income') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddIncomePage(),
                              ),
                            );
                          } else if (value == 'expense') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddExpensePage(),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'income',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle, color: Colors.green),
                                SizedBox(width: 10),
                                Text('Add Income'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'expense',
                            child: Row(
                              children: [
                                Icon(Icons.remove_circle, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Add Expense'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'INCOMES'),
                    Tab(text: 'EXPENSES'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncomeTab(viewModel), _buildExpenseTab(viewModel)],
      ),
    );
  }

  Widget _buildIncomeTab(HomeViewModel viewModel) {
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
      color: Colors.green,
      icon: Icons.account_balance_wallet_outlined,
      emptyMessage: 'No income records found.',
      itemBuilder: (income) => TransactionCard(
        amount: '+RM ${income.netIncome.toStringAsFixed(2)}',
        category: income.category,
        date: DateFormat('dd/MM/yyyy').format(income.incomeDate),
        borderColor: Colors.green,
        amountColor: Colors.green,
        onDelete: () => viewModel.deleteIncome(income.id),
        onTap: () => _showIncomeDetails(context, income),
      ),
    );
  }

  Widget _buildExpenseTab(HomeViewModel viewModel) {
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
      color: Colors.red,
      icon: Icons.shopping_bag_outlined,
      emptyMessage: 'No expense records found.',
      itemBuilder: (expense) => TransactionCard(
        amount: '-RM ${expense.amount.toStringAsFixed(2)}',
        category: expense.category,
        date: DateFormat('dd/MM/yyyy').format(expense.expenseDate),
        borderColor: Colors.red,
        amountColor: Colors.red,
        taxTag: expense.isTaxDeductible ? 'Tax deduct' : null,
        onDelete: () => viewModel.deleteExpense(expense.id),
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
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final Map<String, List<dynamic>> grouped = {};

    for (var item in items) {
      final DateTime date = item is IncomeRecord
          ? item.incomeDate
          : (item as ExpenseRecord).expenseDate;

      final String key = DateFormat('dd MMMM yyyy').format(date);

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(item);
    }

    final List<String> sortedKeys = grouped.keys.toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: color.withOpacity(0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Total:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'RM ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final String dateKey = sortedKeys[index];
              final List<dynamic> dateItems = grouped[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 4,
                    ),
                    child: Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...dateItems.map((item) => itemBuilder(item)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
