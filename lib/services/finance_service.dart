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

  // Stream of all income records (DEBUG VERSION: Fetch all to see what's in DB)
  Stream<List<IncomeRecord>> watchAllIncomes() {
    final uid = _currentUserId;
    print('FinanceService: Current UID: $uid');
    
    return _incomeCollection
        .snapshots()
        .map((snapshot) {
      print('FinanceService: Received ${snapshot.docs.length} total income docs from Firestore');
      
      final records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final docUserId = data['userId'];
        // Log each doc's userId to see if it matches
        if (uid != docUserId) {
          print('Mismatch! Doc ${doc.id} has userId: $docUserId, but current user is: $uid');
        }
        return IncomeRecord.fromMap(doc.id, data);
      }).toList();

      // For now, let's filter in memory so we can see what's happening
      final filtered = records.where((r) => r.userId == uid).toList();
      print('FinanceService: After local filter, ${filtered.length} incomes remain for this user');
      
      // Manual sort since we removed orderBy to avoid index/missing field issues
      filtered.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
      return filtered;
    });
  }

  // Insert Income
  Future<void> insertIncome(IncomeRecord income) {
    print('FinanceService: Inserting income for UID: ${income.userId}');
    return _incomeCollection.add(income.toMap());
  }

  // Delete Income
  Future<void> deleteIncome(String id) {
    return _incomeCollection.doc(id).delete();
  }

  // Stream of all expense records (DEBUG VERSION: Fetch all to see what's in DB)
  Stream<List<ExpenseRecord>> watchAllExpenses() {
    final uid = _currentUserId;
    print('FinanceService: Current UID: $uid');

    return _expenseCollection
        .snapshots()
        .map((snapshot) {
      print('FinanceService: Received ${snapshot.docs.length} total expense docs from Firestore');
      
      final records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExpenseRecord.fromMap(doc.id, data);
      }).toList();

      final filtered = records.where((r) => r.userId == uid).toList();
      print('FinanceService: After local filter, ${filtered.length} expenses remain for this user');

      filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return filtered;
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
