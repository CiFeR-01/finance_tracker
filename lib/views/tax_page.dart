import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class TaxPage extends StatelessWidget {
  const TaxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view tax data.')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tax Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: authService.getUserData(user.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userModel = userSnapshot.data;
          if (userModel == null) {
            return const Center(child: Text('User profile not found.'));
          }

          return StreamBuilder<List<IncomeRecord>>(
            stream: financeService.watchAllIncomes(),
            builder: (context, incomeSnapshot) {
              if (incomeSnapshot.hasError) {
                return Center(child: Text('Income Error: ${incomeSnapshot.error}'));
              }
              return StreamBuilder<List<ExpenseRecord>>(
                stream: financeService.watchAllExpenses(),
                builder: (context, expenseSnapshot) {
                  if (expenseSnapshot.hasError) {
                    return Center(child: Text('Expense Error: ${expenseSnapshot.error}'));
                  }

                  if (incomeSnapshot.connectionState == ConnectionState.waiting ||
                      expenseSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final incomes = incomeSnapshot.data ?? [];
                  final expenses = expenseSnapshot.data ?? [];

                  // DEBUG OVERLAY (Only visible if 0 records found)
                  if (incomes.isEmpty && expenses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No records found in Firestore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Current UID: ${user.uid}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 20),
                            const Text('Troubleshooting Tip:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text('1. Check if "userId" in Firestore matches the UID above.'),
                            const Text('2. Check if collection names are "income_records".'),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/add'),
                              child: const Text('Add a Test Record'),
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  // 1. Get Fixed Reliefs from Profile
                  final List<Map<String, dynamic>> reliefItems = userModel.taxProfile.getFixedReliefItems();

                  // 2. Add Variable Reliefs from Income & Expenses
                  reliefItems.addAll([
                    {
                      'title': 'Life Insurance and EPF',
                      'amount': incomes.fold(0.0, (sum, item) => sum + item.epfAmount),
                      'limit': 7000.0,
                    },
                    {
                      'title': 'SOCSO Contribution',
                      'amount': incomes.fold(0.0, (sum, item) => sum + item.socsoAmount),
                      'limit': 350.0,
                    },
                    {
                      'title': 'Private Retirement Scheme (PRS)',
                      'amount': _sumExpenses(expenses, ['PRS']),
                      'limit': 3000.0,
                    },
                    {
                      'title': 'Education and Medical Insurance',
                      'amount': _sumExpenses(expenses, ['Insurance']),
                      'limit': 4000.0,
                    },
                    {
                      'title': 'Medical Expenses',
                      'amount': _sumExpenses(expenses, ['Medical expenses']),
                      'limit': 10000.0,
                    },
                    {
                      'title': 'Health Screening',
                      'amount': _sumExpenses(expenses, ['Health screening']),
                      'limit': 1000.0,
                    },
                    {
                      'title': 'Lifestyle',
                      'amount': _sumExpenses(expenses, ['Lifestyle']),
                      'limit': 2500.0,
                    },
                    {
                      'title': 'Sports Lifestyle',
                      'amount': _sumExpenses(expenses, ['Sports lifestyle']),
                      'limit': 1000.0,
                    },
                    {
                      'title': 'Education Fees',
                      'amount': _sumExpenses(expenses, ['Education fees']),
                      'limit': 7000.0,
                    },
                    {
                      'title': 'Childcare Fees',
                      'amount': _sumExpenses(expenses, ['Childcare fees']),
                      'limit': 3000.0,
                    },
                    {
                      'title': 'SSPN Net Deposit',
                      'amount': _sumExpenses(expenses, ['SSPN net deposit']),
                      'limit': 8000.0,
                    },
                    {
                      'title': 'Breastfeeding Equipment',
                      'amount': _sumExpenses(expenses, ['Breastfeeding equipment']),
                      'limit': 1000.0,
                    },
                    {
                      'title': 'EV Charging / Composting Machine',
                      'amount': _sumExpenses(expenses, ['EV charging / composting machine']),
                      'limit': 2500.0,
                    },
                    {
                      'title': 'Housing Loan Interest',
                      'amount': _sumExpenses(expenses, ['Housing loan interest']),
                      'limit': 7000.0,
                    },
                  ]);

                  // Filter only claimed items (amount > 0)
                  final claimedReliefs = reliefItems.where((item) => item['amount'] > 0).toList();

                  // Calculate total claimed (with capping)
                  double totalReliefClaimed = reliefItems.fold(0.0, (sum, item) {
                    double amount = item['amount'];
                    double limit = item['limit'];
                    return sum + (amount > limit ? limit : amount);
                  });

                  double totalDonations = _sumExpenses(expenses, ['Donation/Gift']);
                  double totalZakat = _sumExpenses(expenses, ['Zakat']);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Tax Relief Claimed:',
                                  style: TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RM ${totalReliefClaimed.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                if (claimedReliefs.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Text(
                                        'No tax reliefs claimed yet.',
                                        style: TextStyle(color: Colors.grey, fontSize: 16),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: claimedReliefs.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                                    itemBuilder: (context, index) {
                                      final item = claimedReliefs[index];
                                      return _buildReliefItem(
                                        item['title'],
                                        item['amount'],
                                        item['limit'],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (totalDonations > 0) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('Donations & Gifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                          ),
                          const SizedBox(height: 12),
                          _buildSimpleInfoCard('Total Donations', totalDonations),
                          const SizedBox(height: 24),
                        ],
                        if (totalZakat > 0) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('Tax Rebates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                          ),
                          const SizedBox(height: 12),
                          _buildSimpleInfoCard('Zakat', totalZakat, isRebate: true),
                          const SizedBox(height: 24),
                        ],
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              // Navigate to Profile to edit fixed reliefs
                              // This assumes HomePage has a way to switch tabs or ProfilePage is accessible
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Update your Profile to change fixed relief settings.')),
                              );
                            },
                            icon: const Icon(Icons.settings, size: 16),
                            label: const Text('Adjust Fixed Reliefs in Profile'),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  double _sumExpenses(List<ExpenseRecord> expenses, List<String> targetCategories) {
    return expenses
        .where((e) => e.isTaxDeductible && targetCategories.contains(e.category))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Widget _buildReliefItem(String title, double current, double limit) {
    double progress = (current / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 12, // Slimmer progress bar
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: progress >= 1.0 ? Colors.orange : Colors.purple,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'RM ${current.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13, 
              color: progress >= 1.0 ? Colors.orange.shade900 : Colors.black54,
              fontWeight: progress >= 1.0 ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInfoCard(String title, double amount, {bool isRebate = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isRebate ? Colors.green.shade700 : Colors.black),
        ),
      ),
    );
  }
}
