import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_record.dart';
import '../services/finance_service.dart';

class AddIncomeViewModel extends ChangeNotifier {
  final FinanceService _financeService;
  StreamSubscription? _incomeSub;
  List<IncomeRecord> _incomes = [];

  AddIncomeViewModel(this._financeService) {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _incomeSub = _financeService.watchAllIncomes().listen((data) {
        _incomes = data;
        _checkLimits();
      });
    }
  }

  @override
  void dispose() {
    _incomeSub?.cancel();
    super.dispose();
  }

  final List<String> categories = [
    'Salary',
    'Bonus',
    'Freelance',
    'Part-time Job',
    'Allowance',
    'Others'
  ];

  static const double SOCSO_LIMIT = 350.0;
  static const double EPF_LIMIT = 4000.0;

  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
  String? _proofImagePath;

  double _currentEpfInput = 0.0;
  double _currentSocsoInput = 0.0;

  bool _isSocsoLimitReached = false;
  bool _isEpfLimitReached = false;

  // Getters
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  String? get proofImagePath => _proofImagePath;
  bool get isSocsoLimitReached => _isSocsoLimitReached;
  bool get isEpfLimitReached => _isEpfLimitReached;

  double get currentYearSocsoTotal {
    return _incomes
        .where((i) => i.incomeDate.year == _selectedDate.year)
        .fold(0.0, (sum, item) => sum + item.socsoAmount);
  }

  double get currentYearEpfTotal {
    return _incomes
        .where((i) => i.incomeDate.year == _selectedDate.year)
        .fold(0.0, (sum, item) => sum + item.epfAmount);
  }

  // Setters/Actions
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    _checkLimits();
    notifyListeners();
  }

  void setImagePath(String? path) {
    _proofImagePath = path;
    notifyListeners();
  }

  void updateInputs(String epfStr, String socsoStr) {
    _currentEpfInput = double.tryParse(epfStr) ?? 0.0;
    _currentSocsoInput = double.tryParse(socsoStr) ?? 0.0;
    _checkLimits();
  }

  void _checkLimits() {
    final year = _selectedDate.year;
    final totalSocsoInDB = _incomes
        .where((i) => i.incomeDate.year == year)
        .fold(0.0, (sum, item) => sum + item.socsoAmount);
    
    final totalEpfInDB = _incomes
        .where((i) => i.incomeDate.year == year)
        .fold(0.0, (sum, item) => sum + item.epfAmount);

    _isSocsoLimitReached = (totalSocsoInDB + _currentSocsoInput) >= SOCSO_LIMIT;
    _isEpfLimitReached = (totalEpfInDB + _currentEpfInput) >= EPF_LIMIT;
    notifyListeners();
  }

  void clearData() {
    _selectedCategory = 'Salary';
    _selectedDate = DateTime.now();
    _proofImagePath = null;
    _currentEpfInput = 0.0;
    _currentSocsoInput = 0.0;
    _isSocsoLimitReached = false;
    _isEpfLimitReached = false;
    notifyListeners();
  }

  Future<bool> saveIncome({
    required String totalIncomeStr,
    required String epfStr,
    required String socsoStr,
    required String pcbStr,
    required String description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final total = double.tryParse(totalIncomeStr) ?? 0;
    final epf = double.tryParse(epfStr) ?? 0;
    final socso = double.tryParse(socsoStr) ?? 0;
    final pcb = double.tryParse(pcbStr) ?? 0;
    final netIncome = total - epf - socso - pcb;

    final entry = IncomeRecord(
      id: '',
      userId: user.uid,
      totalIncome: total,
      epfAmount: epf,
      socsoAmount: socso,
      pcbAmount: pcb,
      netIncome: netIncome,
      category: _selectedCategory,
      description: description,
      incomeDate: _selectedDate,
      proofImagePath: _proofImagePath,
      createdAt: DateTime.now(),
    );

    await _financeService.insertIncome(entry);
    return true;
  }
}
