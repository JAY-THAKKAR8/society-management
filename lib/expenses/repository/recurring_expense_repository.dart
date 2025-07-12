import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/expenses/model/recurring_expense_model.dart';
import 'package:society_management/expenses/repository/i_recurring_expense_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

@LazySingleton(as: IRecurringExpenseRepository)
class RecurringExpenseRepository extends IRecurringExpenseRepository {
  RecurringExpenseRepository(super.firestore);

  CollectionReference get _recurringExpensesCollection =>
      FirebaseFirestore.instance.collection('recurring_expenses');

  CollectionReference get _paymentsCollection =>
      FirebaseFirestore.instance.collection('recurring_payments');

  @override
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
  }) {
    return Result<RecurringExpenseModel>().tryCatch(
      run: () async {
        final now = DateTime.now();
        final doc = _recurringExpensesCollection.doc();

        // Calculate next due date
        final nextDueDate = _calculateNextDueDate(
          frequency: frequency,
          dueDate: dueDate ?? 1,
          fromDate: now,
        );

        final expenseData = {
          'id': doc.id,
          'name': name,
          'amount': amount,
          'type': type.name,
          'frequency': frequency.name,
          'description': description,
          'vendor_name': vendorName,
          'contact_number': contactNumber,
          'due_date': dueDate,
          'is_active': true,
          'last_paid_date': null,
          'next_due_date': Timestamp.fromDate(nextDueDate),
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
          'created_by': createdBy,
          'line_number': lineNumber,
        };

        await doc.set(expenseData);
        return RecurringExpenseModel.fromJson(expenseData);
      },
    );
  }

  @override
  FirebaseResult<List<RecurringExpenseModel>> getAllRecurringExpenses() {
    return Result<List<RecurringExpenseModel>>().tryCatch(
      run: () async {
        final snapshot = await _recurringExpensesCollection
            .orderBy('created_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => RecurringExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  FirebaseResult<List<RecurringExpenseModel>> getRecurringExpensesByLine({
    required String lineNumber,
  }) {
    return Result<List<RecurringExpenseModel>>().tryCatch(
      run: () async {
        final snapshot = await _recurringExpensesCollection
            .where('line_number', isEqualTo: lineNumber)
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => RecurringExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
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
  }) {
    return Result<RecurringExpenseModel>().tryCatch(
      run: () async {
        final doc = _recurringExpensesCollection.doc(expenseId);
        final currentData = await doc.get();

        if (!currentData.exists) {
          throw Exception('Recurring expense not found');
        }

        final updateData = <String, dynamic>{
          'updated_at': Timestamp.fromDate(DateTime.now()),
        };

        if (name != null) updateData['name'] = name;
        if (amount != null) updateData['amount'] = amount;
        if (type != null) updateData['type'] = type.name;
        if (frequency != null) updateData['frequency'] = frequency.name;
        if (description != null) updateData['description'] = description;
        if (vendorName != null) updateData['vendor_name'] = vendorName;
        if (contactNumber != null) updateData['contact_number'] = contactNumber;
        if (dueDate != null) updateData['due_date'] = dueDate;
        if (isActive != null) updateData['is_active'] = isActive;

        // Recalculate next due date if frequency or due date changed
        if (frequency != null || dueDate != null) {
          final currentExpense = RecurringExpenseModel.fromJson(
            currentData.data() as Map<String, dynamic>,
          );
          
          final nextDueDate = _calculateNextDueDate(
            frequency: frequency ?? currentExpense.frequency,
            dueDate: dueDate ?? currentExpense.dueDate ?? 1,
            fromDate: DateTime.now(),
          );
          
          updateData['next_due_date'] = Timestamp.fromDate(nextDueDate);
        }

        await doc.update(updateData);

        final updatedDoc = await doc.get();
        return RecurringExpenseModel.fromJson(updatedDoc.data() as Map<String, dynamic>);
      },
    );
  }

  @override
  FirebaseResult<void> markAsPaid({
    required String expenseId,
    required DateTime paidDate,
    double? actualAmount,
    String? notes,
    String? paidBy,
  }) {
    return Result<void>().tryCatch(
      run: () async {
        final expenseDoc = _recurringExpensesCollection.doc(expenseId);
        final expenseData = await expenseDoc.get();

        if (!expenseData.exists) {
          throw Exception('Recurring expense not found');
        }

        final expense = RecurringExpenseModel.fromJson(
          expenseData.data() as Map<String, dynamic>,
        );

        // Create payment record
        final paymentDoc = _paymentsCollection.doc();
        final paymentData = {
          'id': paymentDoc.id,
          'recurring_expense_id': expenseId,
          'expense_name': expense.name,
          'scheduled_amount': expense.amount,
          'actual_amount': actualAmount ?? expense.amount,
          'paid_date': Timestamp.fromDate(paidDate),
          'notes': notes,
          'paid_by': paidBy,
          'created_at': Timestamp.fromDate(DateTime.now()),
        };

        await paymentDoc.set(paymentData);

        // Calculate next due date
        final nextDueDate = _calculateNextDueDate(
          frequency: expense.frequency,
          dueDate: expense.dueDate ?? 1,
          fromDate: paidDate,
        );

        // Update recurring expense
        await expenseDoc.update({
          'last_paid_date': Timestamp.fromDate(paidDate),
          'next_due_date': Timestamp.fromDate(nextDueDate),
          'updated_at': Timestamp.fromDate(DateTime.now()),
        });
      },
    );
  }

  @override
  FirebaseResult<List<Map<String, dynamic>>> getPaymentHistory({
    required String expenseId,
  }) {
    return Result<List<Map<String, dynamic>>>().tryCatch(
      run: () async {
        final snapshot = await _paymentsCollection
            .where('recurring_expense_id', isEqualTo: expenseId)
            .orderBy('paid_date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      },
    );
  }

  @override
  FirebaseResult<void> deleteRecurringExpense({
    required String expenseId,
  }) {
    return Result<void>().tryCatch(
      run: () async {
        await _recurringExpensesCollection.doc(expenseId).delete();
        
        // Also delete related payment records
        final payments = await _paymentsCollection
            .where('recurring_expense_id', isEqualTo: expenseId)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (final payment in payments.docs) {
          batch.delete(payment.reference);
        }
        await batch.commit();
      },
    );
  }

  @override
  FirebaseResult<List<RecurringExpenseModel>> getOverdueExpenses() {
    return Result<List<RecurringExpenseModel>>().tryCatch(
      run: () async {
        final now = Timestamp.fromDate(DateTime.now());
        final snapshot = await _recurringExpensesCollection
            .where('is_active', isEqualTo: true)
            .where('next_due_date', isLessThan: now)
            .get();

        return snapshot.docs
            .map((doc) => RecurringExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  FirebaseResult<List<RecurringExpenseModel>> getExpensesDueSoon() {
    return Result<List<RecurringExpenseModel>>().tryCatch(
      run: () async {
        final now = DateTime.now();
        final dueSoonDate = now.add(const Duration(days: 7));
        
        final snapshot = await _recurringExpensesCollection
            .where('is_active', isEqualTo: true)
            .where('next_due_date', isGreaterThan: Timestamp.fromDate(now))
            .where('next_due_date', isLessThan: Timestamp.fromDate(dueSoonDate))
            .get();

        return snapshot.docs
            .map((doc) => RecurringExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  DateTime calculateNextDueDate({
    required RecurringExpenseModel expense,
    DateTime? fromDate,
  }) {
    return _calculateNextDueDate(
      frequency: expense.frequency,
      dueDate: expense.dueDate ?? 1,
      fromDate: fromDate ?? DateTime.now(),
    );
  }

  @override
  FirebaseResult<Map<String, dynamic>> getMonthlyStatistics({
    DateTime? month,
  }) {
    return Result<Map<String, dynamic>>().tryCatch(
      run: () async {
        final targetMonth = month ?? DateTime.now();
        final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);

        // Get all active recurring expenses
        final expensesSnapshot = await _recurringExpensesCollection
            .where('is_active', isEqualTo: true)
            .get();

        final expenses = expensesSnapshot.docs
            .map((doc) => RecurringExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        // Get payments for this month
        final paymentsSnapshot = await _paymentsCollection
            .where('paid_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('paid_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        final totalScheduled = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
        final totalPaid = payments.fold<double>(0, (sum, payment) => sum + (payment['actual_amount'] as num).toDouble());
        final paidCount = payments.length;
        final totalExpenses = expenses.length;

        return {
          'total_scheduled': totalScheduled,
          'total_paid': totalPaid,
          'total_pending': totalScheduled - totalPaid,
          'paid_count': paidCount,
          'total_count': totalExpenses,
          'pending_count': totalExpenses - paidCount,
          'payment_percentage': totalExpenses > 0 ? (paidCount / totalExpenses) * 100 : 0,
        };
      },
    );
  }

  DateTime _calculateNextDueDate({
    required RecurringFrequency frequency,
    required int dueDate,
    required DateTime fromDate,
  }) {
    switch (frequency) {
      case RecurringFrequency.monthly:
        var nextDate = DateTime(fromDate.year, fromDate.month + 1, dueDate);
        // Handle cases where due date doesn't exist in next month (e.g., Feb 30)
        if (nextDate.month != fromDate.month + 1) {
          nextDate = DateTime(fromDate.year, fromDate.month + 2, 0); // Last day of next month
        }
        return nextDate;
        
      case RecurringFrequency.quarterly:
        return DateTime(fromDate.year, fromDate.month + 3, dueDate);
        
      case RecurringFrequency.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, dueDate);
    }
  }
}
