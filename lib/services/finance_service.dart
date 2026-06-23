import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income_record.dart';
import '../models/expense_record.dart';

class FinanceService {
  final CollectionReference _incomeCollection =
      FirebaseFirestore.instance.collection('income_records');
  final CollectionReference _expenseCollection =
      FirebaseFirestore.instance.collection('expense_records');

  // Stream of all income records
  Stream<List<IncomeRecord>> watchAllIncomes() {
    return _incomeCollection
        .orderBy('incomeDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return IncomeRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Insert Income
  Future<void> insertIncome(IncomeRecord income) {
    return _incomeCollection.add(income.toMap());
  }

  // Delete Income
  Future<void> deleteIncome(String id) {
    return _incomeCollection.doc(id).delete();
  }

  // Stream of all expense records
  Stream<List<ExpenseRecord>> watchAllExpenses() {
    return _expenseCollection
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Insert Expense
  Future<void> insertExpense(ExpenseRecord expense) {
    return _expenseCollection.add(expense.toMap());
  }

  // Delete Expense
  Future<void> deleteExpense(String id) {
    return _expenseCollection.doc(id).delete();
  }
}
