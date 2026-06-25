import 'dart:async';
import 'package:flutter/material.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../services/finance_service.dart';

class HomeViewModel extends ChangeNotifier {
  final FinanceService _financeService;

  List<IncomeRecord> _incomes = [];
  List<ExpenseRecord> _expenses = [];
  int _selectedMonth = DateTime.now().month;
  
  StreamSubscription? _incomeSub;
  StreamSubscription? _expenseSub;

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

  int get selectedMonth => _selectedMonth;

  void setSelectedMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  List<IncomeRecord> get incomes => _incomes;
  List<ExpenseRecord> get expenses => _expenses;

  List<IncomeRecord> get filteredIncomes => _incomes
      .where((i) => i.incomeDate.month == _selectedMonth)
      .toList();

  List<ExpenseRecord> get filteredExpenses => _expenses
      .where((e) => e.expenseDate.month == _selectedMonth)
      .toList();

  double get totalIncome => filteredIncomes.fold(0, (sum, item) => sum + item.netIncome);
  double get totalExpenses => filteredExpenses.fold(0, (sum, item) => sum + item.amount);
  
  double get taxReclaimable => filteredExpenses
      .where((e) => e.isTaxDeductible)
      .fold(0, (sum, item) => sum + item.amount);
      
  double get savings => totalIncome - totalExpenses;

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

  Future<void> deleteIncome(String id) async {
    await _financeService.deleteIncome(id);
  }

  Future<void> deleteExpense(String id) async {
    await _financeService.deleteExpense(id);
  }
}
