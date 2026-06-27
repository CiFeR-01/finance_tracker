import 'dart:async';
import 'package:flutter/material.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../services/finance_service.dart';

/// The ViewModel for the Home Page, managing the display and filtering of financial data.
/// 
/// It listens to real-time updates from the [FinanceService] and provides 
/// calculated properties for the UI, such as total income, total expenses, 
/// and tax-reclaimable amounts.
class HomeViewModel extends ChangeNotifier {
  final FinanceService _financeService;

  List<IncomeRecord> _incomes = [];
  List<ExpenseRecord> _expenses = [];
  int _selectedMonth = DateTime.now().month;
  
  StreamSubscription? _incomeSub;
  StreamSubscription? _expenseSub;

  /// Initializes the ViewModel by subscribing to income and expense streams.
  HomeViewModel(this._financeService) {
    _incomeSub = _financeService.watchAllIncomes().listen((data) {
      _incomes = data;
      notifyListeners();
    });
    _expenseSub = _financeService.watchAllExpenses().listen((data) {
      _expenses = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _incomeSub?.cancel();
    _expenseSub?.cancel();
    super.dispose();
  }

  /// The currently selected month for filtering data (1-12).
  int get selectedMonth => _selectedMonth;

  /// Updates the [selectedMonth] and notifies listeners to refresh the UI.
  void setSelectedMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  /// Returns the full list of income records.
  List<IncomeRecord> get incomes => _incomes;

  /// Returns the full list of expense records.
  List<ExpenseRecord> get expenses => _expenses;

  /// Returns income records filtered by the [selectedMonth].
  List<IncomeRecord> get filteredIncomes => _incomes
      .where((i) => i.incomeDate.month == _selectedMonth)
      .toList();

  /// Returns expense records filtered by the [selectedMonth].
  List<ExpenseRecord> get filteredExpenses => _expenses
      .where((e) => e.expenseDate.month == _selectedMonth)
      .toList();

  /// Calculates the total net income for the [selectedMonth].
  double get totalIncome => filteredIncomes.fold(0, (sum, item) => sum + item.netIncome);

  /// Calculates the total expenses for the [selectedMonth].
  double get totalExpenses => filteredExpenses.fold(0, (sum, item) => sum + item.amount);
  
  /// Calculates the total amount of tax-deductible expenses for the [selectedMonth].
  double get taxReclaimable => filteredExpenses
      .where((e) => e.isTaxDeductible)
      .fold(0, (sum, item) => sum + item.amount);
      
  /// Calculates the net savings for the [selectedMonth] (Income - Expenses).
  double get savings => totalIncome - totalExpenses;

  /// Checks if expenses have reached 90% or more of the total income for the selected month.
  bool get isExpenseHigh {
    if (totalIncome <= 0) return false;
    return (totalExpenses / totalIncome) >= 0.9;
  }

  /// Returns the percentage of income spent on expenses.
  double get expensePercentage {
    if (totalIncome <= 0) return 0;
    return (totalExpenses / totalIncome) * 100;
  }

  /// Returns a specific alert message based on the expense-to-income ratio.
  String get budgetAlertMessage {
    final percentage = expensePercentage;
    if (percentage > 100) {
      return 'Your expenses have exceeded your income this month!';
    } else if (percentage == 100) {
      return 'Your expenses have reached 100% of your income.';
    } else {
      return 'Your expenses have reached ${percentage.toStringAsFixed(1)}% of your income this month.';
    }
  }

  /// Identifies the category with the highest spending in the [selectedMonth].
  String get mostSpentCategory {
    final currentExpenses = filteredExpenses;
    if (currentExpenses.isEmpty) return 'None';
    Map<String, double> categoryMap = {};
    for (var e in currentExpenses) {
      categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
    }
    String category = 'None';
    double amount = 0;
    categoryMap.forEach((cat, amt) {
      if (amt > amount) {
        amount = amt;
        category = cat;
      }
    });
    return category;
  }

  /// Returns the highest amount spent in a single category during the [selectedMonth].
  double get mostSpentAmount {
    final currentExpenses = filteredExpenses;
    if (currentExpenses.isEmpty) return 0;
    Map<String, double> categoryMap = {};
    for (var e in currentExpenses) {
      categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
    }
    double amount = 0;
    categoryMap.forEach((cat, amt) {
      if (amt > amount) {
        amount = amt;
      }
    });
    return amount;
  }

  /// Deletes an income record by its [id] through the [FinanceService].
  Future<void> deleteIncome(String id) async {
    await _financeService.deleteIncome(id);
  }

  /// Deletes an expense record by its [id] through the [FinanceService].
  Future<void> deleteExpense(String id) async {
    await _financeService.deleteExpense(id);
  }
}
