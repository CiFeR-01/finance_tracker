import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../models/user_model.dart';
import '../services/finance_service.dart';
import '../services/auth_service.dart';

class TaxViewModel extends ChangeNotifier {
  final FinanceService _financeService;
  final AuthService _authService;
  
  List<IncomeRecord> _incomes = [];
  List<ExpenseRecord> _expenses = [];
  UserModel? _userModel;
  bool _isLoading = true;

  TaxViewModel(this._financeService, this._authService) {
    _init();
  }

  bool get isLoading => _isLoading;
  UserModel? get userModel => _userModel;

  void _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userModel = await _authService.getUserData(user.uid);
      
      _financeService.watchAllIncomes().listen((data) {
        _incomes = data;
        notifyListeners();
      });
      _financeService.watchAllExpenses().listen((data) {
        _expenses = data;
        notifyListeners();
      });
    }
    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> get reliefItems {
    final List<Map<String, dynamic>> items = [];
    
    // 1. Fixed Reliefs from Profile
    if (_userModel != null) {
      items.addAll(_userModel!.taxProfile.getFixedReliefItems());
    }

    // 2. Variable Reliefs
    items.addAll([
      {
        'title': 'Life Insurance and EPF',
        'amount': _incomes.fold(0.0, (sum, item) => sum + item.epfAmount),
        'limit': 7000.0,
      },
      {
        'title': 'SOCSO Contribution',
        'amount': _incomes.fold(0.0, (sum, item) => sum + item.socsoAmount),
        'limit': 350.0,
      },
      {
        'title': 'Private Retirement Scheme (PRS)',
        'amount': _sumExpenses(['PRS']),
        'limit': 3000.0,
      },
      {
        'title': 'Education and Medical Insurance',
        'amount': _sumExpenses(['Insurance']),
        'limit': 4000.0,
      },
      {
        'title': 'Medical Expenses',
        'amount': _sumExpenses(['Medical expenses']),
        'limit': 10000.0,
      },
      {
        'title': 'Health Screening',
        'amount': _sumExpenses(['Health screening']),
        'limit': 1000.0,
      },
      {
        'title': 'Lifestyle',
        'amount': _sumExpenses(['Lifestyle']),
        'limit': 2500.0,
      },
      {
        'title': 'Sports Lifestyle',
        'amount': _sumExpenses(['Sports lifestyle']),
        'limit': 1000.0,
      },
      {
        'title': 'Education Fees',
        'amount': _sumExpenses(['Education fees']),
        'limit': 7000.0,
      },
      {
        'title': 'Childcare Fees',
        'amount': _sumExpenses(['Childcare fees']),
        'limit': 3000.0,
      },
      {
        'title': 'SSPN Net Deposit',
        'amount': _sumExpenses(['SSPN net deposit']),
        'limit': 8000.0,
      },
      {
        'title': 'Breastfeeding Equipment',
        'amount': _sumExpenses(['Breastfeeding equipment']),
        'limit': 1000.0,
      },
      {
        'title': 'EV Charging / Composting Machine',
        'amount': _sumExpenses(['EV charging / composting machine']),
        'limit': 2500.0,
      },
      {
        'title': 'Housing Loan Interest',
        'amount': _sumExpenses(['Housing loan interest']),
        'limit': 7000.0,
      },
    ]);
    
    return items;
  }

  List<Map<String, dynamic>> get claimedReliefs => reliefItems.where((item) => item['amount'] > 0).toList();

  double get totalReliefClaimed {
    return reliefItems.fold(0.0, (sum, item) {
      double amount = item['amount'];
      double limit = item['limit'];
      return sum + (amount > limit ? limit : amount);
    });
  }

  double get totalDonations => _sumExpenses(['Donation/Gift']);
  double get totalZakat => _sumExpenses(['Zakat']);

  double _sumExpenses(List<String> targetCategories) {
    return _expenses
        .where((e) => e.isTaxDeductible && targetCategories.contains(e.category))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  bool get hasNoRecords => _incomes.isEmpty && _expenses.isEmpty;
}
