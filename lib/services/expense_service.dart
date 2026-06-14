import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseService {
  ExpenseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _expenseCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  Future<void> addExpense(Expense expense) {
    return _expenseCollection(expense.userId).doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) {
    return _expenseCollection(expense.userId).doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense({
    required String userId,
    required String expenseId,
  }) {
    return _expenseCollection(userId).doc(expenseId).delete();
  }

  Stream<List<Expense>> watchExpenses(String userId) {
    return _expenseCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => Expense.fromMap(document.id, document.data()))
              .toList(),
        );
  }
}
