import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';

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

  /// Deletes an income record identified by its unique [id].
  Future<void> deleteIncome(String id) {
    return _incomeCollection.doc(id).delete();
  }

  /// Deletes an expense record identified by its unique [id].
  Future<void> deleteExpense(String id) {
    return _expenseCollection.doc(id).delete();
  }
}
