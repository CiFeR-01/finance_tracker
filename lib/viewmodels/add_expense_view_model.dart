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
    _expenseSub = _financeService.watchAllExpenses().listen((data) {
      _expenses = data;
      _checkTaxDeductibilityLimit();
    });
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
  double _currentAmountInput = 0.0;
  bool _isLimitExceeded = false;

  // Getters
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  String? get proofImagePath => _proofImagePath;
  bool get isTaxDeductible => _isTaxDeductible;
  bool get isLimitExceeded => _isLimitExceeded;
  bool get isCategoryDeductible => _categoryLimits.containsKey(_selectedCategory) || _selectedCategory == 'Zakat' || _selectedCategory == 'Donation/Gift';

  double getLimitForCategory(String category) => _categoryLimits[category] ?? 0.0;

  // Setters/Actions
  void setCategory(String category) {
    _selectedCategory = category;
    _isTaxDeductible = isCategoryDeductible;
    _checkTaxDeductibilityLimit();
    notifyListeners();
  }

  void setAmount(String amountStr) {
    _currentAmountInput = double.tryParse(amountStr) ?? 0.0;
    _checkTaxDeductibilityLimit();
    notifyListeners();
  }

  void setTaxDeductible(bool value) {
    _isTaxDeductible = value;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    _checkTaxDeductibilityLimit();
    notifyListeners();
  }

  void setImagePath(String? path) {
    _proofImagePath = path;
    notifyListeners();
  }

  void _checkTaxDeductibilityLimit() {
    if (!_categoryLimits.containsKey(_selectedCategory)) {
      _isLimitExceeded = false;
      return;
    }

    final limit = _categoryLimits[_selectedCategory]!;
    final alreadyClaimed = _expenses
        .where((e) => e.isTaxDeductible && e.category == _selectedCategory && e.expenseDate.year == _selectedDate.year)
        .fold(0.0, (sum, item) => sum + item.amount);

    _isLimitExceeded = (alreadyClaimed + _currentAmountInput) >= limit;
  }

  void clearData() {
    _selectedCategory = 'Medical expenses';
    _selectedDate = DateTime.now();
    _proofImagePath = null;
    _isTaxDeductible = true;
    _currentAmountInput = 0.0;
    _isLimitExceeded = false;
    notifyListeners();
  }

  Future<bool> saveExpense(String amountStr, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final amount = double.tryParse(amountStr) ?? 0.0;

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
