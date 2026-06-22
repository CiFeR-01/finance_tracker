import 'package:flutter/material.dart';
import '../widgets/summary_card.dart';
import '../widgets/most_spent_card.dart';
import '../widgets/monthly_comparison_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_page.dart';

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
    const Center(child: Text('Report Page')),
    const Center(child: Text('Tax Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
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
    return Column(
      children: [
        // 1. Top Header with Purple Gradient
        Container(
          width: double.infinity,
          height: 140,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FinanceTracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
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
                  children: const [
                    SummaryCard(
                      title: 'Expenses',
                      amount: 'RM861.00',
                      backgroundColor: Color(0xFFFFEBEE),
                      textColor: Color(0xFFC62828),
                    ),
                    SummaryCard(
                      title: 'Income',
                      amount: 'RM861.00',
                      backgroundColor: Color(0xFFE8F5E9),
                      textColor: Color(0xFF2E7D32),
                    ),
                    SummaryCard(
                      title: 'Tax Reclaimable',
                      amount: 'RM861.00',
                      backgroundColor: Color(0xFFF3E5F5),
                      textColor: Color(0xFF7B1FA2),
                    ),
                    SummaryCard(
                      title: 'Saving',
                      amount: 'RM-648.00',
                      backgroundColor: Color(0xFFE3F2FD),
                      textColor: Color(0xFF1565C0),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const MostSpentCard(
                  category: 'Groceries',
                  amount: 'RM861.00',
                ),
                const SizedBox(height: 20),
                const MonthlyComparisonCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
