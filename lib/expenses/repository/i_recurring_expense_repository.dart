import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/expenses/model/recurring_expense_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

abstract class IRecurringExpenseRepository {
  final FirebaseFirestore firestore;
  IRecurringExpenseRepository(this.firestore);

  // Create a new recurring expense
  FirebaseResult<RecurringExpenseModel> createRecurringExpense({
    required String name,
    required double amount,
    required RecurringExpenseType type,
    required RecurringFrequency frequency,
    String? description,
    String? vendorName,
    String? contactNumber,
    int? dueDate,
    String? lineNumber,
    String? createdBy,
  });

  // Get all recurring expenses
  FirebaseResult<List<RecurringExpenseModel>> getAllRecurringExpenses();

  // Get recurring expenses by line
  FirebaseResult<List<RecurringExpenseModel>> getRecurringExpensesByLine({
    required String lineNumber,
  });

  // Update a recurring expense
  FirebaseResult<RecurringExpenseModel> updateRecurringExpense({
    required String expenseId,
    String? name,
    double? amount,
    RecurringExpenseType? type,
    RecurringFrequency? frequency,
    String? description,
    String? vendorName,
    String? contactNumber,
    int? dueDate,
    bool? isActive,
  });

  // Mark recurring expense as paid for current period
  FirebaseResult<void> markAsPaid({
    required String expenseId,
    required DateTime paidDate,
    double? actualAmount,
    String? notes,
    String? paidBy,
  });

  // Get payment history for a recurring expense
  FirebaseResult<List<Map<String, dynamic>>> getPaymentHistory({
    required String expenseId,
  });

  // Delete a recurring expense
  FirebaseResult<void> deleteRecurringExpense({
    required String expenseId,
  });

  // Get overdue expenses
  FirebaseResult<List<RecurringExpenseModel>> getOverdueExpenses();

  // Get expenses due soon (within next 7 days)
  FirebaseResult<List<RecurringExpenseModel>> getExpensesDueSoon();

  // Calculate next due date for an expense
  DateTime calculateNextDueDate({
    required RecurringExpenseModel expense,
    DateTime? fromDate,
  });

  // Get monthly expense statistics
  FirebaseResult<Map<String, dynamic>> getMonthlyStatistics({
    DateTime? month,
  });
}
