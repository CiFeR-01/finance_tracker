import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_record.dart';
import '../services/finance_service.dart';

class AddIncomeViewModel extends ChangeNotifier {
  final FinanceService _financeService;

  AddIncomeViewModel(this._financeService);

  final List<String> categories = [
    'Salary',
    'Bonus',
    'Freelance',
    'Part-time Job',
    'Allowance',
    'Others'
  ];

  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
  String? _proofImagePath;

  // Getters
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  String? get proofImagePath => _proofImagePath;

  // Setters/Actions
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
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
    _selectedCategory = 'Salary';
    _selectedDate = DateTime.now();
    _proofImagePath = null;
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
