import 'package:flutter/material.dart';
import '../widgets/transaction_card.dart';
import '../widgets/income_option_sheet.dart';
import '../widgets/expense_option_sheet.dart';
import 'add_income_page.dart';
import 'add_expense_page.dart';
import '../main.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import 'package:intl/intl.dart';

class AddPage extends StatelessWidget {
  const AddPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: const SafeArea(
            child: Center(
              child: Text(
                'Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Incomes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => IncomeOptionSheet(
                            onEnterManually: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddIncomePage()),
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18, color: Colors.black),
                      label: const Text('Add', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<IncomeRecord>>(
                  stream: financeService.watchAllIncomes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('No income records yet', style: TextStyle(color: Colors.grey))),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((income) {
                        return TransactionCard(
                          amount: '+RM ${income.netIncome.toStringAsFixed(2)}',
                          category: income.category,
                          date: DateFormat('dd/MM/yyyy').format(income.incomeDate),
                          borderColor: Colors.green,
                          amountColor: Colors.green,
                          onDelete: () => financeService.deleteIncome(income.id),
                        );
                      }).toList(),
                    );
                  },
                ),

                const Divider(height: 40),

                // Expenses Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expenses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => ExpenseOptionSheet(
                            onEnterManually: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddExpensePage()),
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18, color: Colors.black),
                      label: const Text('Add', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<ExpenseRecord>>(
                  stream: financeService.watchAllExpenses(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('No expense records yet', style: TextStyle(color: Colors.grey))),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((expense) {
                        return TransactionCard(
                          amount: '-RM ${expense.amount.toStringAsFixed(2)}',
                          category: expense.category,
                          date: DateFormat('dd/MM/yyyy').format(expense.expenseDate),
                          borderColor: Colors.red,
                          amountColor: Colors.red,
                          taxTag: expense.isTaxDeductible ? 'Tax deduct' : null,
                          onDelete: () => financeService.deleteExpense(expense.id),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
