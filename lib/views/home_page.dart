import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/summary_card.dart';
import '../widgets/most_spent_card.dart';
import '../widgets/monthly_comparison_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_page.dart';
import 'tax_page.dart';
import 'profile_page.dart';
import 'report_page.dart';
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
      backgroundColor: Colors.white,
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

    return Column(
      children: [
        // 1. Top Header with Purple Gradient
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'FinanceTracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
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
                                color: isSelected ? const Color(0xFFE1BEE7) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const Text(
                    'Manage your Finances',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    SummaryCard(
                      title: 'Expenses',
                      amount: 'RM ${viewModel.totalExpenses.toStringAsFixed(2)}',
                      backgroundColor: const Color(0xFFFFEBEE),
                      textColor: const Color(0xFFC62828),
                    ),
                    SummaryCard(
                      title: 'Income',
                      amount: 'RM ${viewModel.totalIncome.toStringAsFixed(2)}',
                      backgroundColor: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF2E7D32),
                    ),
                    SummaryCard(
                      title: 'Tax Reclaimable',
                      amount: 'RM ${viewModel.taxReclaimable.toStringAsFixed(2)}',
                      backgroundColor: const Color(0xFFF3E5F5),
                      textColor: const Color(0xFF7B1FA2),
                    ),
                    SummaryCard(
                      title: 'Saving',
                      amount: 'RM ${viewModel.savings.toStringAsFixed(2)}',
                      backgroundColor: const Color(0xFFE3F2FD),
                      textColor: const Color(0xFF1565C0),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                MostSpentCard(
                  category: viewModel.mostSpentCategory,
                  amount: 'RM ${viewModel.mostSpentAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 20),
                MonthlyComparisonCard(
                  incomes: viewModel.incomes,
                  expenses: viewModel.expenses,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
