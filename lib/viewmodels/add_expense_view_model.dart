import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_record.dart';
import '../services/finance_service.dart';

class AddExpenseViewModel extends ChangeNotifier {
  final FinanceService _financeService;

  AddExpenseViewModel(this._financeService);

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

  String _selectedCategory = 'Medical expenses';
  DateTime _selectedDate = DateTime.now();
  String? _proofImagePath;
  bool _isTaxDeductible = true; // Default to true since Medical is deductible

  // Getters
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  String? get proofImagePath => _proofImagePath;
  bool get isTaxDeductible => _isTaxDeductible;
  bool get isCategoryDeductible => _deductibleCategories.contains(_selectedCategory);

  // Setters/Actions
  void setCategory(String category) {
    _selectedCategory = category;
    if (isCategoryDeductible) {
      _isTaxDeductible = true;
    } else {
      _isTaxDeductible = false;
    }
    notifyListeners();
  }

  void setTaxDeductible(bool value) {
    if (isCategoryDeductible) {
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
