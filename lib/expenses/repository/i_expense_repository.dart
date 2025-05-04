import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/expenses/model/expense_category_model.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

abstract class IExpenseRepository {
  final FirebaseFirestore firestore;
  IExpenseRepository(this.firestore);

  // Existing methods
  FirebaseResult<List<ExpenseModel>> getAllExpenses();

  FirebaseResult<ExpenseModel> addExpense({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> items,
    String? description,
    String? categoryId,
    String? lineNumber,
    String? vendorName,
    String? receiptUrl,
    ExpensePriority priority = ExpensePriority.medium,
  });

  FirebaseResult<ExpenseModel> getExpense({
    required String expenseId,
  });

  FirebaseResult<void> deleteExpense({
    required String expenseId,
  });

  // New methods for categories
  FirebaseResult<List<ExpenseCategoryModel>> getAllCategories();

  FirebaseResult<ExpenseCategoryModel> addCategory({
    required String name,
    String? description,
    String? iconName,
    String? colorHex,
    bool isCommonExpense = true,
    bool isRecurring = false,
  });

  FirebaseResult<ExpenseCategoryModel> getCategory({
    required String categoryId,
  });

  FirebaseResult<void> deleteCategory({
    required String categoryId,
  });

  // Methods for line-specific expenses
  FirebaseResult<List<ExpenseModel>> getExpensesByLine({
    required String lineNumber,
  });

  // Dashboard statistics
  FirebaseResult<Map<String, dynamic>> getExpenseStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
}
