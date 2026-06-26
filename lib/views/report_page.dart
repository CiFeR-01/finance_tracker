import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import '../services/pdf_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _selectedMonth = DateTime.now().month;
  String _selectedCategory = 'All Categories';

  final List<String> _categories = [
    'All Categories',
    'Medical expenses',
    'Health screening',
    'Lifestyle',
    'Sports lifestyle',
    'Education fees',
    'Childcare fees',
    'SSPN net deposit',
    'Breastfeeding equipment',
    'EV charging / composting machine',
    'Housing loan interest',
    'Private Retirement Scheme',
    'Insurance',
    'Zakat',
    'Donation/Gift',
    'Others'
  ];

  void _generateMonthlyReport(HomeViewModel viewModel) async {
    try {
      final filteredIncomes = viewModel.incomes.where((i) => i.incomeDate.month == _selectedMonth).toList();
      final filteredExpenses = viewModel.expenses.where((e) => e.expenseDate.month == _selectedMonth).toList();

      if (filteredIncomes.isEmpty && filteredExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available for the selected month.')),
        );
        return;
      }

      // Show a "loading" snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing PDF...'), duration: Duration(seconds: 1)),
      );

      await PdfService.generateMonthlyReport(
        month: _selectedMonth,
        incomes: filteredIncomes,
        expenses: filteredExpenses,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  void _generateCategoryReport(HomeViewModel viewModel) async {
    try {
      var filteredExpenses = viewModel.expenses.where((e) => e.expenseDate.month == _selectedMonth).toList();
      
      if (_selectedCategory != 'All Categories') {
        filteredExpenses = filteredExpenses.where((e) => e.category == _selectedCategory).toList();
      }

      if (filteredExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No data available for $_selectedCategory in the selected month.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing PDF...'), duration: Duration(seconds: 1)),
      );

      await PdfService.generateCategoryReport(
        month: _selectedMonth,
        category: _selectedCategory,
        expenses: filteredExpenses,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20),
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
            child: const Center(
              child: Text(
                'Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
                  const Text(
                    'Generate Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create detailed financial summaries in PDF format for your records and tax filing',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Select Month Section
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Select Month',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: List.generate(12, (index) => index + 1).map((int month) {
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(DateFormat('MMMM').format(DateTime(2024, month))),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMonth = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Complete Monthly Report Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5), // Light purple
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFE1BEE7), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Monthly Report',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Includes all income, expenses, category breakdown, and transaction details',
                          style: TextStyle(fontSize: 13, color: Colors.purple[700]),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _generateMonthlyReport(viewModel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0), // Purple button
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Generate Monthly Report',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category-Specific Report Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA), // Light teal
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFB2EBF2), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category-Specific Report',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF006064)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Generate a detailed report for a specific expense category with attached receipts',
                          style: TextStyle(fontSize: 13, color: Colors.teal[700]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Category',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.teal[900]),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.teal.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.teal.shade200),
                            ),
                          ),
                          items: _categories.map((String category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _generateCategoryReport(viewModel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4), // Teal button
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Generate Category Report',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
