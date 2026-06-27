import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_record.dart';
import '../services/finance_service.dart';

class AddExpenseViewModel extends ChangeNotifier {
  final FinanceService _financeService;
  StreamSubscription? _expenseSub;
  List<ExpenseRecord> _expenses = [];

  AddExpenseViewModel(this._financeService) {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _expenseSub = _financeService.watchAllExpenses().listen((data) {
        _expenses = data;
        _checkTaxDeductibilityLimit();
      });
    }
  }

  @override
  void dispose() {
    _expenseSub?.cancel();
    super.dispose();
  }

  final List<String> categories = [
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

  final List<String> _deductibleCategories = [
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
    'Donation/Gift'
  ];

  final Map<String, double> _categoryLimits = {
    'Medical expenses': 10000.0,
    'Health screening': 1000.0,
    'Lifestyle': 2500.0,
    'Sports lifestyle': 1000.0,
    'Education fees': 7000.0,
    'Childcare fees': 3000.0,
    'SSPN net deposit': 8000.0,
    'Breastfeeding equipment': 1000.0,
    'EV charging / composting machine': 2500.0,
    'Housing loan interest': 7000.0,
    'Private Retirement Scheme': 3000.0,
    'Insurance': 4000.0,
  };

  String _selectedCategory = 'Medical expenses';
  DateTime _selectedDate = DateTime.now();
  String? _proofImagePath;
  bool _isTaxDeductible = true;
  double _currentAmount = 0.0;
  bool _isLimitExceeded = false;

  // Getters
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  String? get proofImagePath => _proofImagePath;
  bool get isTaxDeductible => _isTaxDeductible;
  bool get isCategoryDeductible => _deductibleCategories.contains(_selectedCategory);
  bool get isLimitExceeded => _isLimitExceeded;

  double getRemainingLimit(String category) {
    final limit = _categoryLimits[category];
    if (limit == null) return double.infinity;

    final alreadyClaimed = _expenses
        .where((e) => e.isTaxDeductible && e.category == category)
        .fold(0.0, (sum, item) => sum + item.amount);
    
    return limit - alreadyClaimed;
  }

  // Setters/Actions
  void setCategory(String category) {
    _selectedCategory = category;
    _checkTaxDeductibilityLimit();
    notifyListeners();
  }

  void setAmount(String amountStr) {
    _currentAmount = double.tryParse(amountStr) ?? 0.0;
    _checkTaxDeductibilityLimit();
    notifyListeners();
  }

  void _checkTaxDeductibilityLimit() {
    if (!isCategoryDeductible) {
      _isLimitExceeded = false;
      _isTaxDeductible = false;
      return;
    }

    final remaining = getRemainingLimit(_selectedCategory);
    
    if (_currentAmount > remaining) {
      _isLimitExceeded = true;
      _isTaxDeductible = false;
    } else {
      _isLimitExceeded = false;
      // We don't automatically set it back to true if it was RM 0 before, 
      // but usually when user selects category it starts as deductible if applicable.
      if (_currentAmount == 0 || (_isTaxDeductible == false && _isLimitExceeded == false)) {
         // Optionally reset to true if we just came back from an exceeded state
         // But let's keep it simple: if it's within limit, we default it to true when changing categories
      }
    }
  }

  void setTaxDeductible(bool value) {
    if (isCategoryDeductible && !_isLimitExceeded) {
      _isTaxDeductible = value;
      notifyListeners();
    }
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setImagePath(String? path) {
    _proofImagePath = path;
    notifyListeners();
  }

  void clearData() {
    _selectedCategory = 'Medical expenses';
    _selectedDate = DateTime.now();
    _proofImagePath = null;
    _isTaxDeductible = true;
    _currentAmount = 0.0;
    _isLimitExceeded = false;
    notifyListeners();
  }

  Future<bool> saveExpense(String amountStr, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final amount = double.tryParse(amountStr);
    if (amount == null) return false;

    final entry = ExpenseRecord(
      id: '',
      userId: user.uid,
      amount: amount,
      category: _selectedCategory,
      description: description,
      expenseDate: _selectedDate,
      proofImagePath: _proofImagePath,
      isTaxDeductible: _isTaxDeductible,
      createdAt: DateTime.now(),
    );

    await _financeService.insertExpense(entry);
    return true;
  }
}
