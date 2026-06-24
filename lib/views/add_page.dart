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

class AddPage extends StatelessWidget {
  const AddPage({super.key});

  void _showIncomeDetails(BuildContext context, IncomeRecord income) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Income Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
              const Divider(height: 32),
              _buildDetailRow('Amount', 'RM ${income.totalIncome.toStringAsFixed(2)}'),
              _buildDetailRow('EPF', 'RM ${income.epfAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Socso', 'RM ${income.socsoAmount.toStringAsFixed(2)}'),
              _buildDetailRow('PCB', 'RM ${income.pcbAmount.toStringAsFixed(2)}'),
              const Divider(height: 32),
              _buildDetailRow('Net Income', 'RM ${income.netIncome.toStringAsFixed(2)}', isBold: true, color: Colors.green),
              _buildDetailRow('Category', income.category),
              _buildDetailRow('Date', DateFormat('dd MMMM yyyy').format(income.incomeDate)),
              if (income.description != null && income.description!.isNotEmpty)
                _buildDetailRow('Description', income.description!),
              if (income.proofImagePath != null) ...[
                const SizedBox(height: 20),
                const Text('Proof of Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(File(income.proofImagePath!), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Text('Image not found')),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Expense Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
              const Divider(height: 32),
              _buildDetailRow('Amount', 'RM ${expense.amount.toStringAsFixed(2)}', isBold: true, color: Colors.red),
              _buildDetailRow('Category', expense.category),
              _buildDetailRow('Date', DateFormat('dd MMMM yyyy').format(expense.expenseDate)),
              _buildDetailRow('Tax Deductible', expense.isTaxDeductible ? 'Yes' : 'No'),
              if (expense.description != null && expense.description!.isNotEmpty)
                _buildDetailRow('Description', expense.description!),
              if (expense.proofImagePath != null) ...[
                const SizedBox(height: 20),
                const Text('Proof of Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(File(expense.proofImagePath!), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Text('Image not found')),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
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
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Column(
      children: [
        // Top Header
        Container(
          width: double.infinity,
          height: 100,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: DropdownButton<int>(
                      value: viewModel.selectedMonth,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFE1BEE7)),
                      underline: Container(),
                      dropdownColor: const Color(0xFF7B1FA2),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          viewModel.setSelectedMonth(newValue);
                        }
                      },
                      items: List.generate(12, (index) => index + 1).map((int month) {
                        final isSelected = month == viewModel.selectedMonth;
                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(
                            DateFormat('MMM').format(DateTime(2024, month)),
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFE1BEE7) : Colors.white, // Light purple if selected
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.add, color: Colors.white, size: 28),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      onSelected: (value) {
                        if (value == 'income') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddIncomePage()),
                          );
                        } else if (value == 'expense') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddExpensePage()),
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
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Incomes Section
                const Text(
                  'Incomes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (viewModel.filteredIncomes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No income records for this month', style: TextStyle(color: Colors.grey))),
                  )
                else
                  Column(
                    children: viewModel.filteredIncomes.map((income) {
                      return TransactionCard(
                        amount: '+RM ${income.netIncome.toStringAsFixed(2)}',
                        category: income.category,
                        date: DateFormat('dd/MM/yyyy').format(income.incomeDate),
                        borderColor: Colors.green,
                        amountColor: Colors.green,
                        onDelete: () => viewModel.deleteIncome(income.id),
                        onTap: () => _showIncomeDetails(context, income),
                      );
                    }).toList(),
                  ),

                const Divider(height: 40),

                // Expenses Section
                const Text(
                  'Expenses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (viewModel.filteredExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No expense records for this month', style: TextStyle(color: Colors.grey))),
                  )
                else
                  Column(
                    children: viewModel.filteredExpenses.map((expense) {
                      return TransactionCard(
                        amount: '-RM ${expense.amount.toStringAsFixed(2)}',
                        category: expense.category,
                        date: DateFormat('dd/MM/yyyy').format(expense.expenseDate),
                        borderColor: Colors.red,
                        amountColor: Colors.red,
                        taxTag: expense.isTaxDeductible ? 'Tax deduct' : null,
                        onDelete: () => viewModel.deleteExpense(expense.id),
                        onTap: () => _showExpenseDetails(context, expense),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
