import 'package:flutter/material.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../services/finance_service.dart';

class HomeViewModel extends ChangeNotifier {
  final FinanceService _financeService;

  List<IncomeRecord> _incomes = [];
  List<ExpenseRecord> _expenses = [];

  HomeViewModel(this._financeService) {
    _financeService.watchAllIncomes().listen((data) {
      _incomes = data;
      notifyListeners();
    });
    _financeService.watchAllExpenses().listen((data) {
      _expenses = data;
      notifyListeners();
    });
  }

  List<IncomeRecord> get incomes => _incomes;
  List<ExpenseRecord> get expenses => _expenses;

  double get totalIncome => _incomes.fold(0, (sum, item) => sum + item.netIncome);
  double get totalExpenses => _expenses.fold(0, (sum, item) => sum + item.amount);
  
  double get taxReclaimable => _expenses
      .where((e) => e.isTaxDeductible)
      .fold(0, (sum, item) => sum + item.amount);
      
  double get savings => totalIncome - totalExpenses;

  String get mostSpentCategory {
    if (_expenses.isEmpty) return 'None';
    Map<String, double> categoryMap = {};
    for (var e in _expenses) {
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
    if (_expenses.isEmpty) return 0;
    Map<String, double> categoryMap = {};
    for (var e in _expenses) {
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
