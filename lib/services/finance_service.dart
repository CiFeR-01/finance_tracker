import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';

class FinanceService {
  final CollectionReference _incomeCollection =
      FirebaseFirestore.instance.collection('income_records');
  final CollectionReference _expenseCollection =
      FirebaseFirestore.instance.collection('expense_records');

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Stream of income records for the CURRENT user only
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

  // Stream of expense records for the CURRENT user only
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

  // Insert Income
  Future<void> insertIncome(IncomeRecord income) {
    return _incomeCollection.add(income.toMap());
  }

  // Insert Expense
  Future<void> insertExpense(ExpenseRecord expense) {
    return _expenseCollection.add(expense.toMap());
  }

  // Delete Income
  Future<void> deleteIncome(String id) {
    return _incomeCollection.doc(id).delete();
  }

  // Delete Expense
  Future<void> deleteExpense(String id) {
    return _expenseCollection.doc(id).delete();
  }
}
