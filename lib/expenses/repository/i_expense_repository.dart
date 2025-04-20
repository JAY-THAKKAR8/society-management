import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

abstract class IExpenseRepository {
  final FirebaseFirestore firestore;
  IExpenseRepository(this.firestore);

  FirebaseResult<List<ExpenseModel>> getAllExpenses();

  FirebaseResult<ExpenseModel> addExpense({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> items,
  });

  FirebaseResult<ExpenseModel> getExpense({
    required String expenseId,
  });

  FirebaseResult<void> deleteExpense({
    required String expenseId,
  });
}
