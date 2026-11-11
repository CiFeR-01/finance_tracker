import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';
import '../models/recurring_rule.dart';
import '../models/tax_rates.dart';
import 'reminder_planner.dart';

/// A service class that handles all financial data operations with Firestore.
/// 
/// This service provides methods to watch, insert, and delete income and expense
/// records, ensuring that data is scoped to the currently authenticated user.
class FinanceService {
  /// Reference to the Firestore collection containing income records.
  final CollectionReference _incomeCollection =
      FirebaseFirestore.instance.collection('income_records');

  /// Reference to the Firestore collection containing expense records.
  final CollectionReference _expenseCollection =
      FirebaseFirestore.instance.collection('expense_records');

  /// Retrieves the unique identifier of the currently signed-in user.
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Provides a real-time [Stream] of [IncomeRecord]s for the current user.
  /// 
  /// The records are filtered by the user's ID on the server side and 
  /// sorted by date in descending order on the client side.
  Stream<List<IncomeRecord>> watchAllIncomes() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);

    // Server-side filtering is safer and prevents cross-user data leaks
    return _incomeCollection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return IncomeRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList()
        ..sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
    });
  }

  /// Provides a real-time [Stream] of [ExpenseRecord]s for the current user.
  /// 
  /// The records are filtered by the user's ID and sorted by date 
  /// in descending order.
  Stream<List<ExpenseRecord>> watchAllExpenses() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);

    return _expenseCollection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList()
        ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    });
  }

  /// Adds a new [IncomeRecord] to the database.
  /// 
  /// Returns a [Future] that completes when the operation is finished.
  Future<void> insertIncome(IncomeRecord income) {
    return _incomeCollection.add(income.toMap());
  }

  /// Adds a new [ExpenseRecord] to the database.
  /// 
  /// Returns a [Future] that completes when the operation is finished.
  Future<void> insertExpense(ExpenseRecord expense) {
    return _expenseCollection.add(expense.toMap());
  }

  /// Re-creates a deleted [IncomeRecord] under its original id (used by Undo).
  Future<void> restoreIncome(IncomeRecord income) {
    return _incomeCollection.doc(income.id).set(income.toMap());
  }

  /// Re-creates a deleted [ExpenseRecord] under its original id (used by Undo).
  Future<void> restoreExpense(ExpenseRecord expense) {
    return _expenseCollection.doc(expense.id).set(expense.toMap());
  }

  /// Saves changes to an existing [IncomeRecord], keeping its id.
  Future<void> updateIncome(IncomeRecord income) => restoreIncome(income);

  /// Saves changes to an existing [ExpenseRecord], keeping its id.
  Future<void> updateExpense(ExpenseRecord expense) => restoreExpense(expense);

  /// Deletes an income record identified by its unique [id].
  Future<void> deleteIncome(String id) {
    return _incomeCollection.doc(id).delete();
  }

  /// Deletes an expense record identified by its unique [id].
  Future<void> deleteExpense(String id) {
    return _expenseCollection.doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // Budgets and recurring rules live on the user's own document
  // (users/{uid}), which the user can already read and update.

  DocumentReference? get _userDoc {
    final uid = _currentUserId;
    return uid == null ? null : FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Stream<Map<String, dynamic>> _watchUserField(String field) {
    final doc = _userDoc;
    if (doc == null) return Stream.value({});
    return doc.snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      final value = data?[field];
      return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    });
  }

  /// Monthly spending limit per expense category.
  Stream<Map<String, double>> watchBudgets() => _watchUserField('budgets').map(
        (m) => m.map((k, v) => MapEntry(k, (v as num).toDouble())),
      );

  /// Sets (or with null, removes) the monthly limit for [category].
  Future<void> setBudget(String category, double? limit) async {
    final doc = _userDoc;
    if (doc == null) return;
    await doc.update({FieldPath(['budgets', category]): limit ?? FieldValue.delete()});
  }

  /// Reminder switches from the Profile tab.
  Stream<ReminderSettings> watchReminderSettings() =>
      _watchUserField('settings').map(ReminderSettings.fromMap);

  /// [key] is `billReminders` or `filingReminders`.
  Future<void> setSetting(String key, bool value) async {
    final doc = _userDoc;
    if (doc == null) return;
    await doc.update({FieldPath(['settings', key]): value});
  }

  Stream<List<RecurringRule>> watchRecurringRules() => _watchUserField('recurring').map(
        (m) => m.entries
            .map((e) => RecurringRule.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
            .toList()
          ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth)),
      );

  Future<void> saveRecurringRule(RecurringRule rule) async {
    final doc = _userDoc;
    if (doc == null) return;
    await doc.update({FieldPath(['recurring', rule.id]): rule.toMap()});
  }

  Future<void> deleteRecurringRule(String id) async {
    final doc = _userDoc;
    if (doc == null) return;
    await doc.update({FieldPath(['recurring', id]): FieldValue.delete()});
  }

  /// Creates every missing monthly record for [rule] up to today, then moves
  /// the rule's `lastGenerated` forward. Safe to run repeatedly: each record
  /// has a fixed id per month, so a re-run overwrites rather than duplicates.
  Future<int> generateDueRecords(RecurringRule rule, {DateTime? now}) async {
    final uid = _currentUserId;
    if (uid == null) return 0;
    final dates = rule.dueDates(now ?? DateTime.now());
    if (dates.isEmpty) return 0;
    for (final date in dates) {
      final desc = rule.description.isEmpty ? 'Recurring' : rule.description;
      if (rule.isIncome) {
        await restoreIncome(IncomeRecord(
          id: rule.recordIdFor(date),
          userId: uid,
          totalIncome: rule.amount,
          epfAmount: rule.epf,
          socsoAmount: rule.socso,
          pcbAmount: rule.pcb,
          netIncome: rule.netIncome,
          category: rule.category,
          description: desc,
          incomeDate: date,
          createdAt: DateTime.now(),
        ));
      } else {
        await restoreExpense(ExpenseRecord(
          id: rule.recordIdFor(date),
          userId: uid,
          amount: rule.amount,
          category: rule.category,
          description: desc,
          expenseDate: date,
          isTaxDeductible: rule.isTaxDeductible,
          createdAt: DateTime.now(),
        ));
      }
    }
    await saveRecurringRule(rule.withLastGenerated(dates.last));
    return dates.length;
  }

  /// Tax rates for [year] from `tax_config/{year}`, falling back to the
  /// figures bundled in the app when the document is missing or unreadable.
  Stream<TaxRates> watchTaxRates(int year) async* {
    yield TaxRates.bundled(year);
    try {
      await for (final snap in FirebaseFirestore.instance.collection('tax_config').doc('$year').snapshots()) {
        final data = snap.data();
        yield data == null ? TaxRates.bundled(year) : TaxRates.fromMap(year, data);
      }
    } catch (_) {
      // No read access or offline: keep using the bundled rates.
    }
  }
}
