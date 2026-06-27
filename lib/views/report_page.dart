import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import '../services/pdf_service.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';

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

  void _generateMonthlyReport(List<IncomeRecord> filteredIncomes, List<ExpenseRecord> filteredExpenses) async {
    try {
      if (filteredIncomes.isEmpty && filteredExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Transaction Records available for the selected month.')),
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

  void _generateCategoryReport(List<ExpenseRecord> filteredExpenses) async {
    try {
      if (filteredExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No expenses available for $_selectedCategory in the selected month.')),
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

    // Calculate data for the selected month
    final filteredIncomes = viewModel.incomes.where((i) => i.incomeDate.month == _selectedMonth).toList();
    final filteredExpenses = viewModel.expenses.where((e) => e.expenseDate.month == _selectedMonth).toList();
    
    final totalIn = filteredIncomes.fold(0.0, (sum, i) => sum + i.netIncome);
    final totalEx = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final balance = totalIn - totalEx;

    // Filtered expenses for category report
    final categoryExpenses = _selectedCategory == 'All Categories' 
        ? filteredExpenses 
        : filteredExpenses.where((e) => e.category == _selectedCategory).toList();

    // Past month comparison data
    int prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    int prevYear = _selectedMonth == 1 ? DateTime.now().year - 1 : DateTime.now().year;
    
    final prevIncomes = viewModel.incomes.where((i) => i.incomeDate.month == prevMonth && i.incomeDate.year == prevYear).toList();
    final prevExpenses = viewModel.expenses.where((e) => e.expenseDate.month == prevMonth && e.expenseDate.year == prevYear).toList();
    
    final prevTotalIn = prevIncomes.fold(0.0, (sum, i) => sum + i.netIncome);
    final prevTotalEx = prevExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final prevBalance = prevTotalIn - prevTotalEx;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                  'Reports',
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
                  const Text(
                    'Generate Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create detailed financial summaries in PDF format for your records and tax filing',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 25),

                  // Select Month Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF9C27B0)),
                          const SizedBox(width: 8),
                          Text(
                            'Select Month',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('yyyy').format(DateTime.now()),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      filled: true,
                      fillColor: Colors.grey[50],
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

                  // Monthly Summary Card
                  _buildSummaryPreview(totalIn, totalEx, balance),
                  const SizedBox(height: 25),

                  const Text(
                    'Available Report Types',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Complete Monthly Report',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.assignment_outlined, color: Colors.purple[300], size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Includes all income, expenses, category breakdown, and transaction details',
                          style: TextStyle(fontSize: 13, color: Colors.purple[700]),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildMiniStat(Icons.south_west, '${filteredIncomes.length} Incomes')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMiniStat(Icons.north_east, '${filteredExpenses.length} Expenses')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _generateMonthlyReport(filteredIncomes, filteredExpenses),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0), // Purple button
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Category-Specific Report',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF006064)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.category_outlined, color: Colors.teal[300], size: 20),
                          ],
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
                        const SizedBox(height: 12),
                        _buildMiniStat(Icons.receipt_long_outlined, '${categoryExpenses.length} transactions found', color: Colors.teal[700]!),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _generateCategoryReport(categoryExpenses),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4), // Teal button
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
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
                  const SizedBox(height: 25),

                  _buildComparisonSection(
                    currentIn: totalIn,
                    currentEx: totalEx,
                    currentSav: balance,
                    prevIn: prevTotalIn,
                    prevEx: prevTotalEx,
                    prevSav: prevBalance,
                    prevMonthName: DateFormat('MMMM').format(DateTime(prevYear, prevMonth)),
                    currentMonthName: DateFormat('MMMM').format(DateTime(2024, _selectedMonth)),
                  ),
                  
                  const SizedBox(height: 30),
                  // Info Footer
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                        const SizedBox(height: 8),
                        Text(
                          'Reports are saved to your device Downloads folder',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildComparisonSection({
    required double currentIn,
    required double currentEx,
    required double currentSav,
    required double prevIn,
    required double prevEx,
    required double prevSav,
    required String prevMonthName,
    required String currentMonthName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Month-over-Month Comparison',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Comparing $currentMonthName with $prevMonthName',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildComparisonRow('Income ($currentMonthName)', currentIn, prevIn, Colors.green),
              const Divider(height: 30),
              _buildComparisonRow('Expenses ($currentMonthName)', currentEx, prevEx, Colors.red),
              const Divider(height: 30),
              _buildComparisonRow('Net Savings ($currentMonthName)', currentSav, prevSav, Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String title, double current, double prev, Color color) {
    double diff = current - prev;
    bool isIncrease = diff >= 0;
    bool isExpenses = title.toLowerCase().contains('expenses');
    
    // For expenses, an increase is "bad" (red), decrease is "good" (green)
    // For income/savings, an increase is "good" (green), decrease is "bad" (red)
    Color trendColor = isExpenses 
        ? (isIncrease ? Colors.red : Colors.green) 
        : (isIncrease ? Colors.green : Colors.red);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(
                'Prev: RM ${prev.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${current.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'RM ${diff.abs().toStringAsFixed(2)} ${isIncrease ? 'more' : 'lesser'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPreview(double income, double expense, double balance) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildSummaryItem('INCOME', income, const Color(0xFF4CAF50))),
            VerticalDivider(color: Colors.grey[200], thickness: 1, width: 1),
            Expanded(child: _buildSummaryItem('EXPENSES', expense, const Color(0xFFF44336))),
            VerticalDivider(color: Colors.grey[200], thickness: 1, width: 1),
            Expanded(child: _buildSummaryItem('BALANCE', balance, balance >= 0 ? const Color(0xFF2196F3) : Colors.orange)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String text, {Color color = const Color(0xFF9C27B0)}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color.withOpacity(0.8)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
