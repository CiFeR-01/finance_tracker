import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_record.dart';
import '../models/categories.dart';
import '../models/recurring_rule.dart';
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

  final List<String> categories = expenseCategories;

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

  String _selectedCategory = 'Food & dining';
  DateTime _selectedDate = DateTime.now();
  String? _proofImagePath;
  bool _isTaxDeductible = false;
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
        .where((e) =>
            e.isTaxDeductible &&
            e.category == category &&
            // When editing, the record's own old amount must not count against it.
            e.id != _editing?.id &&
            // Relief limits reset every tax year, so only count the year being claimed.
            e.expenseDate.year == _selectedDate.year)
        .fold(0.0, (sum, item) => sum + item.amount);
    
    return limit - alreadyClaimed;
  }

  // Setters/Actions
  void setCategory(String category) {
    _selectedCategory = category;
    // Relief categories start ticked; the limit check below can untick them.
    _isTaxDeductible = isCategoryDeductible;
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
    // The remaining relief depends on the tax year of the date.
    _checkTaxDeductibilityLimit();
    notifyListeners();
  }

  void setImagePath(String? path) {
    _proofImagePath = path;
    notifyListeners();
  }

  ExpenseRecord? _editing;

  /// The record being edited, or null when adding a new one.
  ExpenseRecord? get editing => _editing;
  bool get isEditing => _editing != null;

  /// Fills the form state from [record] so it can be changed and saved back.
  void loadForEdit(ExpenseRecord record) {
    _editing = record;
    _selectedCategory = categories.contains(record.category) ? record.category : 'Others';
    _selectedDate = record.expenseDate;
    _proofImagePath = record.proofImagePath;
    _currentAmount = record.amount;
    _repeatMonthly = false;
    _isLimitExceeded = false;
    _isTaxDeductible = record.isTaxDeductible && isCategoryDeductible;
    _checkTaxDeductibilityLimit();
    notifyListeners();
  }

  bool _repeatMonthly = false;

  /// When on, saving also creates a monthly recurring rule from this entry.
  bool get repeatMonthly => _repeatMonthly;

  void setRepeatMonthly(bool value) {
    _repeatMonthly = value;
    notifyListeners();
  }

  void clearData() {
    _editing = null;
    _selectedCategory = 'Food & dining';
    _selectedDate = DateTime.now();
    _proofImagePath = null;
    _isTaxDeductible = false;
    _currentAmount = 0.0;
    _isLimitExceeded = false;
    _repeatMonthly = false;
    notifyListeners();
  }

  Future<bool> saveExpense(String amountStr, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final amount = double.tryParse(amountStr);
    if (amount == null) return false;

    final editing = _editing;
    final entry = ExpenseRecord(
      id: editing?.id ?? '',
      userId: user.uid,
      amount: amount,
      category: _selectedCategory,
      description: description,
      expenseDate: _selectedDate,
      proofImagePath: _proofImagePath,
      isTaxDeductible: _isTaxDeductible,
      createdAt: editing?.createdAt ?? DateTime.now(),
    );

    if (editing != null) {
      await _financeService.updateExpense(entry);
      return true;
    }
    await _financeService.insertExpense(entry);
    if (_repeatMonthly) {
      await _financeService.saveRecurringRule(RecurringRule(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        isIncome: false,
        amount: amount,
        category: _selectedCategory,
        description: description,
        dayOfMonth: _selectedDate.day,
        isTaxDeductible: _isTaxDeductible,
        // This month's record was just saved, so the rule starts next month.
        lastGenerated: DateTime(_selectedDate.year, _selectedDate.month),
      ));
    }
    return true;
  }
}
