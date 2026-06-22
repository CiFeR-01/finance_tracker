import 'package:flutter/material.dart';
import '../widgets/transaction_card.dart';
import '../widgets/income_option_sheet.dart';
import 'add_income_page.dart';
import '../main.dart';
import '../database/app_database.dart';
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
                  stream: database.watchAllIncomes(),
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
                          onDelete: () => database.deleteIncome(income.id),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add expense feature will be added later')),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18, color: Colors.black),
                      label: const Text('Add', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Placeholder Expense Card
                TransactionCard(
                  amount: '-RM 80.00',
                  category: 'Groceries',
                  date: '04/05/2026',
                  borderColor: Colors.red,
                  amountColor: Colors.red,
                  taxTag: 'Tax deduct',
                  onDelete: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
