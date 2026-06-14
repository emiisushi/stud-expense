import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({required ExpenseService expenseService})
      : _expenseService = expenseService;

  final ExpenseService _expenseService;
  final Uuid _uuid = const Uuid();

  Stream<List<Expense>> watchExpenses(String userId) {
    return _expenseService.watchExpenses(userId);
  }

  Future<String?> addExpense({
    required String userId,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String? remarks,
  }) async {
    try {
      final expense = Expense(
        id: _uuid.v4(),
        userId: userId,
        title: title,
        amount: amount,
        category: category,
        date: date,
        remarks: remarks,
      );
      await _expenseService.addExpense(expense);
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to save expense.';
    } catch (_) {
      return 'Unable to save expense.';
    }
  }

  Future<String?> updateExpense(Expense expense) async {
    try {
      await _expenseService.updateExpense(expense);
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to update expense.';
    } catch (_) {
      return 'Unable to update expense.';
    }
  }

  Future<String?> deleteExpense({
    required String userId,
    required String expenseId,
  }) async {
    try {
      await _expenseService.deleteExpense(userId: userId, expenseId: expenseId);
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to delete expense.';
    } catch (_) {
      return 'Unable to delete expense.';
    }
  }
}
