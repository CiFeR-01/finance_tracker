import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_record.dart';
import '../models/recurring_rule.dart';
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

  static const double socsoLimit = 350.0;
  static const double epfLimit = 4000.0;

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
    final totalSocsoInDB = _otherIncomes
        .where((i) => i.incomeDate.year == year)
        .fold(0.0, (sum, item) => sum + item.socsoAmount);
    
    final totalEpfInDB = _otherIncomes
        .where((i) => i.incomeDate.year == year)
        .fold(0.0, (sum, item) => sum + item.epfAmount);

    _isSocsoLimitReached = (totalSocsoInDB + _currentSocsoInput) >= socsoLimit;
    _isEpfLimitReached = (totalEpfInDB + _currentEpfInput) >= epfLimit;
    notifyListeners();
  }

  IncomeRecord? _editing;

  /// The record being edited, or null when adding a new one.
  IncomeRecord? get editing => _editing;
  bool get isEditing => _editing != null;

  /// Fills the form state from [record] so it can be changed and saved back.
  void loadForEdit(IncomeRecord record) {
    _editing = record;
    _selectedCategory = categories.contains(record.category) ? record.category : 'Others';
    _selectedDate = record.incomeDate;
    _proofImagePath = record.proofImagePath;
    _repeatMonthly = false;
    // The limit check compares the year's total plus this entry, so leave the
    // record's own amounts out of the stored total while editing it.
    _currentEpfInput = record.epfAmount;
    _currentSocsoInput = record.socsoAmount;
    _checkLimits();
  }

  Iterable<IncomeRecord> get _otherIncomes => _incomes.where((i) => i.id != _editing?.id);

  bool _repeatMonthly = false;

  /// When on, saving also creates a monthly recurring rule from this entry.
  bool get repeatMonthly => _repeatMonthly;

  void setRepeatMonthly(bool value) {
    _repeatMonthly = value;
    notifyListeners();
  }

  void clearData() {
    _editing = null;
    _selectedCategory = 'Salary';
    _selectedDate = DateTime.now();
    _proofImagePath = null;
    _currentEpfInput = 0.0;
    _currentSocsoInput = 0.0;
    _isSocsoLimitReached = false;
    _isEpfLimitReached = false;
    _repeatMonthly = false;
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

    final editing = _editing;
    final entry = IncomeRecord(
      id: editing?.id ?? '',
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
      createdAt: editing?.createdAt ?? DateTime.now(),
    );

    if (editing != null) {
      await _financeService.updateIncome(entry);
      return true;
    }
    await _financeService.insertIncome(entry);
    if (_repeatMonthly) {
      await _financeService.saveRecurringRule(RecurringRule(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        isIncome: true,
        amount: total,
        epf: epf,
        socso: socso,
        pcb: pcb,
        category: _selectedCategory,
        description: description,
        dayOfMonth: _selectedDate.day,
        // This month's record was just saved, so the rule starts next month.
        lastGenerated: DateTime(_selectedDate.year, _selectedDate.month),
      ));
    }
    return true;
  }
}
