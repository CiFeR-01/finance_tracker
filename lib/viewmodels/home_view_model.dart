import 'dart:async';
import 'package:flutter/material.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../models/recurring_rule.dart';
import '../models/tax_rates.dart';
import '../services/reminder_planner.dart';
import '../services/reminder_service.dart';
import '../services/finance_service.dart';

/// The ViewModel for the Home Page, managing the display and filtering of financial data.
/// 
/// It listens to real-time updates from the [FinanceService] and provides 
/// calculated properties for the UI, such as total income, total expenses, 
/// and tax-reclaimable amounts.
class HomeViewModel extends ChangeNotifier {
  final FinanceService _financeService;

  List<IncomeRecord> _incomes = [];
  List<ExpenseRecord> _expenses = [];
  /// The selected period, normalised to the first day of a month.
  DateTime _selectedPeriod = DateTime(DateTime.now().year, DateTime.now().month);
  
  Map<String, double> _budgets = {};
  List<RecurringRule> _recurringRules = [];

  StreamSubscription? _incomeSub;
  StreamSubscription? _expenseSub;
  StreamSubscription? _budgetSub;
  StreamSubscription? _recurringSub;
  StreamSubscription? _settingsSub;
  ReminderSettings _reminderSettings = const ReminderSettings();
  bool _settingsLoaded = false;

  /// Initializes the ViewModel by subscribing to income and expense streams.
  HomeViewModel(this._financeService) {
    _incomeSub = _financeService.watchAllIncomes().listen((data) {
      _incomes = data;
      notifyListeners();
    });
    _expenseSub = _financeService.watchAllExpenses().listen((data) {
      _expenses = data;
      notifyListeners();
    });
    _budgetSub = _financeService.watchBudgets().listen((data) {
      _budgets = data;
      notifyListeners();
    });
    _recurringSub = _financeService.watchRecurringRules().listen((rules) {
      _recurringRules = rules;
      notifyListeners();
      _catchUpRecurring(rules);
      _syncReminders();
    });
    _settingsSub = _financeService.watchReminderSettings().listen((s) {
      _reminderSettings = s;
      _settingsLoaded = true;
      notifyListeners();
      _syncReminders();
    });
  }

  bool _catchingUp = false;

  /// Creates any monthly records that came due since the app was last open.
  Future<void> _catchUpRecurring(List<RecurringRule> rules) async {
    if (_catchingUp) return;
    _catchingUp = true;
    try {
      final now = DateTime.now();
      for (final rule in rules) {
        if (rule.dueDates(now).isNotEmpty) {
          await _financeService.generateDueRecords(rule, now: now);
        }
      }
    } catch (e) {
      debugPrint('Recurring catch-up failed: $e');
    } finally {
      _catchingUp = false;
    }
  }

  // -------------------------------------------------------------- Reminders

  ReminderSettings get reminderSettings => _reminderSettings;

  /// The next e-Filing deadline (for last year's income, or next year's once
  /// this year's has passed).
  static DateTime nextFilingDeadline(DateTime now) {
    final thisYear = TaxRates.bundled(now.year - 1).filingDeadline!;
    return now.isAfter(thisYear) ? TaxRates.bundled(now.year).filingDeadline! : thisYear;
  }

  /// Upcoming reminders, for showing in the app.
  List<PlannedReminder> get upcomingReminders {
    final now = DateTime.now();
    return ReminderPlanner.plan(
      settings: _reminderSettings,
      rules: _recurringRules,
      now: now,
      filingDeadline: nextFilingDeadline(now),
    );
  }

  void _syncReminders() {
    // Wait for the stored settings so a cold start doesn't clear reminders.
    if (!_settingsLoaded) return;
    ReminderService.schedule(upcomingReminders);
  }

  /// Turns a reminder type on or off. Returns false if notification
  /// permission was refused.
  Future<bool> setReminder({bool? bills, bool? filing}) async {
    if ((bills ?? false) || (filing ?? false)) {
      final granted = await ReminderService.requestPermission();
      if (!granted) return false;
    }
    if (bills != null) await _financeService.setSetting('billReminders', bills);
    if (filing != null) await _financeService.setSetting('filingReminders', filing);
    return true;
  }

  @override
  void dispose() {
    _incomeSub?.cancel();
    _expenseSub?.cancel();
    _budgetSub?.cancel();
    _recurringSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  /// The currently selected period (year and month) used for filtering data.
  DateTime get selectedPeriod => _selectedPeriod;

  /// The currently selected month for filtering data (1-12).
  int get selectedMonth => _selectedPeriod.month;

  /// The year of the currently selected period.
  int get selectedYear => _selectedPeriod.year;

  /// Updates the selected period and notifies listeners to refresh the UI.
  void setSelectedPeriod(DateTime period) {
    _selectedPeriod = DateTime(period.year, period.month);
    notifyListeners();
  }

  /// Periods offered in month pickers, newest first.
  ///
  /// Always includes the last 12 months plus any older month that has records,
  /// so past years stay reachable without listing empty months.
  List<DateTime> get availablePeriods {
    final now = DateTime.now();
    final periods = <DateTime>{
      for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i),
      for (final i in _incomes) DateTime(i.incomeDate.year, i.incomeDate.month),
      for (final e in _expenses) DateTime(e.expenseDate.year, e.expenseDate.month),
      _selectedPeriod,
    };
    return periods.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Whether [date] falls inside the selected period.
  bool isInSelectedPeriod(DateTime date) =>
      date.year == _selectedPeriod.year && date.month == _selectedPeriod.month;

  /// Returns the full list of income records.
  List<IncomeRecord> get incomes => _incomes;

  /// Returns the full list of expense records.
  List<ExpenseRecord> get expenses => _expenses;

  /// Returns income records filtered by the [selectedPeriod].
  List<IncomeRecord> get filteredIncomes => _incomes
      .where((i) => isInSelectedPeriod(i.incomeDate))
      .toList();

  /// Returns expense records filtered by the [selectedPeriod].
  List<ExpenseRecord> get filteredExpenses => _expenses
      .where((e) => isInSelectedPeriod(e.expenseDate))
      .toList();

  /// Calculates the total net income for the [selectedPeriod].
  double get totalIncome => filteredIncomes.fold(0, (sum, item) => sum + item.netIncome);

  /// Calculates the total expenses for the [selectedPeriod].
  double get totalExpenses => filteredExpenses.fold(0, (sum, item) => sum + item.amount);
  
  /// Calculates the total amount of tax-deductible expenses for the [selectedPeriod].
  double get taxReclaimable => filteredExpenses
      .where((e) => e.isTaxDeductible)
      .fold(0, (sum, item) => sum + item.amount);
      
  /// Calculates the net savings for the [selectedPeriod] (Income - Expenses).
  double get savings => totalIncome - totalExpenses;

  /// Checks if expenses have reached 90% or more of the total income for the selected month.
  bool get isExpenseHigh {
    if (totalIncome <= 0) return false;
    return (totalExpenses / totalIncome) >= 0.9;
  }

  /// Returns the percentage of income spent on expenses.
  double get expensePercentage {
    if (totalIncome <= 0) return 0;
    return (totalExpenses / totalIncome) * 100;
  }

  /// Returns a specific alert message based on the expense-to-income ratio.
  String get budgetAlertMessage {
    final percentage = expensePercentage;
    if (percentage > 100) {
      return 'Your expenses have exceeded your income this month!';
    } else if (percentage == 100) {
      return 'Your expenses have reached 100% of your income.';
    } else {
      return 'Your expenses have reached ${percentage.toStringAsFixed(1)}% of your income this month.';
    }
  }

  /// Identifies the category with the highest spending in the [selectedPeriod].
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

  /// Returns the highest amount spent in a single category during the [selectedPeriod].
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

  /// Restores a previously deleted income record (Undo).
  Future<void> restoreIncome(IncomeRecord income) async {
    await _financeService.restoreIncome(income);
  }

  /// Restores a previously deleted expense record (Undo).
  Future<void> restoreExpense(ExpenseRecord expense) async {
    await _financeService.restoreExpense(expense);
  }

  /// Deletes an income record by its [id] through the [FinanceService].
  Future<void> deleteIncome(String id) async {
    await _financeService.deleteIncome(id);
  }

  /// Deletes an expense record by its [id] through the [FinanceService].
  Future<void> deleteExpense(String id) async {
    await _financeService.deleteExpense(id);
  }

  // ---------------------------------------------------------------- Budgets

  /// Monthly limit per category.
  Map<String, double> get budgets => _budgets;

  /// Spending per category in the selected period.
  Map<String, double> get spentByCategory {
    final map = <String, double>{};
    for (final e in filteredExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  /// Every category with a budget, most-used first.
  List<BudgetStatus> get budgetStatuses {
    final spent = spentByCategory;
    final list = _budgets.entries
        .where((e) => e.value > 0)
        .map((e) => BudgetStatus(e.key, e.value, spent[e.key] ?? 0))
        .toList()
      ..sort((a, b) => b.ratio.compareTo(a.ratio));
    return list;
  }

  /// Budgets at 90% or more in the selected period.
  List<BudgetStatus> get budgetsNearLimit => budgetStatuses.where((b) => b.ratio >= 0.9).toList();

  Future<void> setBudget(String category, double? limit) => _financeService.setBudget(category, limit);

  // -------------------------------------------------------------- Recurring

  List<RecurringRule> get recurringRules => _recurringRules;

  Future<void> deleteRecurringRule(String id) => _financeService.deleteRecurringRule(id);
}

/// How much of one category's monthly budget has been used.
class BudgetStatus {
  final String category;
  final double limit;
  final double spent;
  const BudgetStatus(this.category, this.limit, this.spent);

  double get ratio => limit <= 0 ? 0 : spent / limit;
  double get remaining => limit - spent;
  bool get isOver => spent > limit;
}
