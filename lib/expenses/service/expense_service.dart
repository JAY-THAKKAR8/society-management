import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/expenses/model/recurring_expense_model.dart';

class RecurringExpenseService {
  static RecurringExpenseService? _instance;
  static RecurringExpenseService get instance => _instance ??= RecurringExpenseService._();
  RecurringExpenseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new recurring expense
  Future<RecurringExpenseModel?> createRecurringExpense({
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
  }) async {
    try {
      final now = DateTime.now();
      final doc = _firestore.collection('recurring_expenses').doc();

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
    } catch (e) {
      print('Error creating recurring expense: $e');
      return null;
    }
  }

  // Get all recurring expenses
  Future<List<RecurringExpenseModel>> getAllRecurringExpenses() async {
    try {
      final snapshot = await _firestore.collection('recurring_expenses').orderBy('created_at', descending: true).get();

      return snapshot.docs.map((doc) => RecurringExpenseModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting recurring expenses: $e');
      return [];
    }
  }

  // Get recurring expenses by line
  Future<List<RecurringExpenseModel>> getRecurringExpensesByLine({
    required String lineNumber,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('recurring_expenses')
          .where('line_number', isEqualTo: lineNumber)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => RecurringExpenseModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting recurring expenses by line: $e');
      return [];
    }
  }

  // Update a monthly fixed expense
  Future<bool> updateMonthlyFixedExpense({
    required String expenseId,
    String? name,
    double? amount,
    RecurringExpenseType? type,
    String? description,
    String? vendorName,
    String? contactNumber,
    int? dueDate,
    bool? isActive,
  }) async {
    try {
      print('Updating expense with ID: $expenseId'); // Debug log
      final doc = _firestore.collection('monthly_fixed_expenses').doc(expenseId);
      final updateData = <String, dynamic>{
        'updated_at': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updateData['name'] = name;
      if (amount != null) updateData['amount'] = amount;
      if (type != null) updateData['type'] = type.name;
      if (description != null) updateData['description'] = description;
      if (vendorName != null) updateData['vendor_name'] = vendorName;
      if (contactNumber != null) updateData['contact_number'] = contactNumber;
      if (dueDate != null) updateData['due_date'] = dueDate;
      if (isActive != null) updateData['is_active'] = isActive;

      await doc.update(updateData);
      print('Successfully updated expense in Firebase'); // Debug log
      return true;
    } catch (e) {
      print('Error updating monthly fixed expense: $e');
      return false;
    }
  }

  // Mark recurring expense as paid
  Future<bool> markAsPaid({
    required String expenseId,
    required DateTime paidDate,
    double? actualAmount,
    String? notes,
    String? paidBy,
  }) async {
    try {
      // Create payment record
      final paymentDoc = _firestore.collection('recurring_payments').doc();
      final paymentData = {
        'id': paymentDoc.id,
        'recurring_expense_id': expenseId,
        'actual_amount': actualAmount,
        'paid_date': Timestamp.fromDate(paidDate),
        'notes': notes,
        'paid_by': paidBy,
        'created_at': Timestamp.fromDate(DateTime.now()),
      };

      await paymentDoc.set(paymentData);

      // Update recurring expense
      await _firestore.collection('recurring_expenses').doc(expenseId).update({
        'last_paid_date': Timestamp.fromDate(paidDate),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error marking as paid: $e');
      return false;
    }
  }

  // Delete a monthly fixed expense
  Future<bool> deleteMonthlyFixedExpense({
    required String expenseId,
  }) async {
    try {
      print('Deleting expense with ID: $expenseId'); // Debug log
      await _firestore.collection('monthly_fixed_expenses').doc(expenseId).delete();
      print('Successfully deleted expense from Firebase'); // Debug log
      return true;
    } catch (e) {
      print('Error deleting monthly fixed expense: $e');
      return false;
    }
  }

  // Calculate next due date
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

  // Validate expense data
  String? validateExpenseData({
    required String name,
    required double amount,
    required RecurringExpenseType type,
    required RecurringFrequency frequency,
    int? dueDate,
    String? contactNumber,
  }) {
    if (name.trim().isEmpty) {
      return 'Expense name is required';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (dueDate != null && (dueDate < 1 || dueDate > 31)) {
      return 'Due date must be between 1 and 31';
    }

    if (contactNumber != null && contactNumber.isNotEmpty) {
      // Basic phone number validation
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
      if (!phoneRegex.hasMatch(contactNumber)) {
        return 'Invalid contact number format';
      }
    }

    return null; // No validation errors
  }

  // Create a monthly fixed expense (admin controlled)
  Future<RecurringExpenseModel?> createMonthlyFixedExpense({
    required String name,
    required double amount,
    required RecurringExpenseType type,
    String? description,
    String? vendorName,
    String? contactNumber,
    int dueDate = 10,
    String? createdBy,
  }) async {
    try {
      final now = DateTime.now();
      final doc = _firestore.collection('monthly_fixed_expenses').doc();

      final expenseData = {
        'id': doc.id,
        'name': name,
        'amount': amount,
        'type': type.name,
        'frequency': 'monthly', // Default to monthly for fixed expenses
        'description': description,
        'vendor_name': vendorName,
        'contact_number': contactNumber,
        'due_date': dueDate,
        'is_active': true,
        'is_paid': false,
        'due_month': null,
        'due_year': null,
        'last_paid_date': null,
        'next_due_date': null,
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
        'created_by': createdBy ?? 'Admin',
        'line_number': null,
      };

      await doc.set(expenseData);
      print('Successfully created expense: $name - ₹$amount'); // Debug log
      return RecurringExpenseModel.fromJson(expenseData);
    } catch (e) {
      print('Error creating monthly fixed expense: $e');
      return null;
    }
  }

  // Get all monthly fixed expenses
  Future<List<RecurringExpenseModel>> getMonthlyFixedExpenses() async {
    try {
      final snapshot = await _firestore.collection('monthly_fixed_expenses').where('is_active', isEqualTo: true).get();

      final expenses = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Loaded expense: ${data['name']} - ${data['amount']}'); // Debug log
        return RecurringExpenseModel.fromJson(data);
      }).toList();

      print('Total expenses loaded: ${expenses.length}'); // Debug log
      return expenses;
    } catch (e) {
      print('Error getting monthly fixed expenses: $e');
      return [];
    }
  }

  // Check if expense is already paid for specific month/year
  Future<bool> isExpenseAlreadyPaid({
    required String expenseId,
    required int paidMonth,
    required int paidYear,
  }) async {
    try {
      final existingPayments = await _firestore
          .collection('monthly_expense_payments')
          .where('expense_id', isEqualTo: expenseId)
          .where('paid_month', isEqualTo: paidMonth)
          .where('paid_year', isEqualTo: paidYear)
          .get();

      return existingPayments.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if expense already paid: $e');
      return false;
    }
  }

  // Get payment history for an expense
  Future<List<Map<String, dynamic>>> getExpensePaymentHistory({
    required String expenseId,
  }) async {
    try {
      print('Getting payment history for expense: $expenseId'); // Debug log

      final payments =
          await _firestore.collection('monthly_expense_payments').where('expense_id', isEqualTo: expenseId).get();

      print('Found ${payments.docs.length} payments'); // Debug log

      final paymentList = payments.docs.map((doc) {
        final data = doc.data();
        print('Payment data: $data'); // Debug log
        return {
          'id': doc.id,
          'expense_name': data['expense_name'],
          'amount': data['actual_amount'] ?? data['scheduled_amount'],
          'paid_month': data['paid_month'],
          'paid_year': data['paid_year'],
          'paid_date': data['paid_date'],
          'notes': data['notes'],
          'paid_by': data['paid_by'],
        };
      }).toList();

      // Sort manually since Firebase orderBy might have issues
      paymentList.sort((a, b) {
        final yearCompare = (b['paid_year'] as int).compareTo(a['paid_year'] as int);
        if (yearCompare != 0) return yearCompare;
        return (b['paid_month'] as int).compareTo(a['paid_month'] as int);
      });

      return paymentList;
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  // Mark monthly fixed expense as paid for specific month
  Future<bool> markMonthlyFixedExpenseAsPaid({
    required String expenseId,
    required String expenseName,
    required double amount,
    required DateTime paidDate,
    required int paidMonth,
    required int paidYear,
    double? actualAmount,
    String? notes,
    String? paidBy,
  }) async {
    try {
      // First check if already paid for this month/year
      final alreadyPaid = await isExpenseAlreadyPaid(
        expenseId: expenseId,
        paidMonth: paidMonth,
        paidYear: paidYear,
      );

      if (alreadyPaid) {
        print('Expense already paid for $paidMonth/$paidYear');
        return false; // Return false to indicate payment was not processed
      }
      // Create payment record
      final paymentDoc = _firestore.collection('monthly_expense_payments').doc();
      await paymentDoc.set({
        'id': paymentDoc.id,
        'expense_id': expenseId,
        'expense_name': expenseName,
        'scheduled_amount': amount,
        'actual_amount': actualAmount ?? amount,
        'paid_date': Timestamp.fromDate(paidDate),
        'paid_month': paidMonth,
        'paid_year': paidYear,
        'notes': notes,
        'paid_by': paidBy,
        'created_at': Timestamp.fromDate(DateTime.now()),
      });

      // Add to monthly expense dashboard
      await _addToMonthlyExpenseDashboard(
        expenseName,
        actualAmount ?? amount,
        paidDate,
        paidMonth,
        paidYear,
      );

      // Add to main society expenses collection for expense dashboard
      await _addToSocietyExpenses(
        expenseName,
        actualAmount ?? amount,
        paidDate,
        notes,
        paidBy,
      );

      return true;
    } catch (e) {
      print('Error marking monthly expense as paid: $e');
      return false;
    }
  }

  // Add to monthly expense dashboard
  Future<void> _addToMonthlyExpenseDashboard(
    String expenseName,
    double amount,
    DateTime paidDate,
    int paidMonth,
    int paidYear,
  ) async {
    try {
      final monthYear = '$paidMonth-$paidYear';
      final dashboardDoc = _firestore.collection('monthly_expense_dashboard').doc(monthYear);

      final docSnapshot = await dashboardDoc.get();

      if (docSnapshot.exists) {
        // Update existing dashboard
        final data = docSnapshot.data()!;
        final expenses = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
        expenses.add({
          'name': expenseName,
          'amount': amount,
          'paid_date': Timestamp.fromDate(paidDate),
        });

        await dashboardDoc.update({
          'expenses': expenses,
          'total_amount': (data['total_amount'] ?? 0.0) + amount,
          'updated_at': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Create new dashboard entry
        await dashboardDoc.set({
          'month': paidMonth,
          'year': paidYear,
          'month_year': monthYear,
          'expenses': [
            {
              'name': expenseName,
              'amount': amount,
              'paid_date': Timestamp.fromDate(paidDate),
            }
          ],
          'total_amount': amount,
          'created_at': Timestamp.fromDate(DateTime.now()),
          'updated_at': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      print('Error adding to monthly expense dashboard: $e');
    }
  }

  // Add to main society expenses collection (for expense dashboard)
  Future<void> _addToSocietyExpenses(
    String expenseName,
    double amount,
    DateTime paidDate,
    String? notes,
    String? paidBy,
  ) async {
    try {
      final now = DateTime.now();
      final expenseDoc = _firestore.collection('expenses').doc();

      final expenseData = {
        'id': expenseDoc.id,
        'name': expenseName,
        'description': notes ?? 'Monthly fixed expense payment',
        'total_amount': amount,
        'start_date': Timestamp.fromDate(paidDate),
        'end_date': Timestamp.fromDate(paidDate),
        'category_id': 'monthly_fixed', // Special category for monthly fixed expenses
        'category_name': 'Monthly Fixed Expenses',
        'line_number': null, // Common expense
        'line_name': null,
        'vendor_name': null,
        'receipt_url': null,
        'priority': 'medium',
        'status': 'completed',
        'items': [
          {
            'id': '1',
            'name': expenseName,
            'price': amount,
          }
        ],
        'created_at': Timestamp.fromDate(paidDate),
        'updated_at': Timestamp.fromDate(now),
        'created_by': paidBy ?? 'Admin',
      };

      await expenseDoc.set(expenseData);

      // Update dashboard stats using the proper method
      try {
        // Use the dashboard repository to properly update all dashboard stats
        await _updateDashboardStatsProper(amount);
      } catch (e) {
        print('Error updating dashboard stats: $e');
      }

      // Log activity
      final activityDoc = _firestore.collection('activities').doc();
      await activityDoc.set({
        'id': activityDoc.id,
        'message': '💰 Monthly fixed expense paid: $expenseName (₹${amount.toStringAsFixed(2)})',
        'type': 'expense',
        'timestamp': Timestamp.fromDate(now),
      });

      print('Successfully added $expenseName to society expenses'); // Debug log
    } catch (e) {
      print('Error adding to society expenses: $e');
    }
  }

  // Update dashboard stats using proper method
  Future<void> _updateDashboardStatsProper(double amount) async {
    try {
      print('Updating dashboard stats with amount: ₹$amount'); // Debug log

      // Update admin dashboard stats directly
      final now = Timestamp.fromDate(DateTime.now());
      final adminStatsRef = _firestore.collection('admin_dashboard_stats').doc('stats');

      // Get current stats and recalculate total expenses from expenses collection
      final expensesSnapshot = await _firestore.collection('expenses').get();
      double totalExpenses = 0.0;

      print('Found ${expensesSnapshot.docs.length} expense documents for dashboard update'); // Debug log

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        // Try multiple field names that might contain the amount
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpenses += amount;
        print('Processing expense: ${data['name'] ?? 'Unknown'} - Amount: ₹$amount'); // Debug log
      }

      print('Calculated total expenses from collection: ₹$totalExpenses'); // Debug log

      // Update admin stats with calculated total
      await adminStatsRef.update({
        'total_expenses': totalExpenses,
        'updated_at': now,
      });

      // Update line head dashboard stats for all lines
      final lineStatsSnapshot = await _firestore.collection('line_head_dashboard_stats').get();
      print('Found ${lineStatsSnapshot.docs.length} line head stats to update'); // Debug log

      for (final doc in lineStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      // Update user dashboard stats for all users
      final userStatsSnapshot = await _firestore.collection('user_dashboard_stats').get();
      print('Found ${userStatsSnapshot.docs.length} user stats to update'); // Debug log

      for (final doc in userStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      print('Successfully updated all dashboard stats with total: ₹$totalExpenses'); // Debug log
    } catch (e) {
      print('Error updating dashboard stats: $e');
    }
  }

  // Force refresh all dashboard stats (call this after payment)
  Future<void> refreshAllDashboardStats() async {
    try {
      print('Force refreshing all dashboard stats...'); // Debug log

      // Calculate total expenses from expenses collection
      final expensesSnapshot = await _firestore.collection('expenses').get();
      double totalExpenses = 0.0;

      print('Found ${expensesSnapshot.docs.length} expense documents'); // Debug log

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        // Try multiple field names that might contain the amount
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpenses += amount;
        print('Expense: ${data['name'] ?? 'Unknown'} - Amount: ₹$amount'); // Debug log
      }

      final now = Timestamp.fromDate(DateTime.now());

      // Force update admin dashboard stats
      await _firestore.collection('admin_dashboard_stats').doc('stats').update({
        'total_expenses': totalExpenses,
        'updated_at': now,
      });

      // Force update all line head dashboard stats
      final lineStatsSnapshot = await _firestore.collection('line_head_dashboard_stats').get();
      for (final doc in lineStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      // Force update all user dashboard stats
      final userStatsSnapshot = await _firestore.collection('user_dashboard_stats').get();
      for (final doc in userStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      print('Force refresh completed. Total expenses: ₹$totalExpenses'); // Debug log
    } catch (e) {
      print('Error force refreshing dashboard stats: $e');
    }
  }

  // Test method to verify payment flow
  Future<void> testPaymentFlow() async {
    try {
      print('=== TESTING PAYMENT FLOW ===');

      // Test 1: Check if collections exist
      final adminStats = await _firestore.collection('admin_dashboard_stats').doc('stats').get();
      print('Admin stats exists: ${adminStats.exists}');

      final monthlyDashboard = await _firestore.collection('monthly_expense_dashboard').get();
      print('Monthly dashboard docs: ${monthlyDashboard.docs.length}');

      final expenses = await _firestore.collection('expenses').get();
      print('Expenses docs: ${expenses.docs.length}');

      final payments = await _firestore.collection('monthly_expense_payments').get();
      print('Payment docs: ${payments.docs.length}');

      print('=== TEST COMPLETE ===');
    } catch (e) {
      print('Test error: $e');
    }
  }

  // Debug method to check expenses collection
  Future<void> debugExpensesCollection() async {
    try {
      print('=== DEBUGGING EXPENSES COLLECTION ===');

      final expensesSnapshot = await _firestore.collection('expenses').get();
      print('Total expense documents: ${expensesSnapshot.docs.length}');

      double totalAmount = 0.0;

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalAmount += amount;

        print('Document ID: ${doc.id}');
        print('  Name: ${data['name'] ?? 'Unknown'}');
        print('  Total Amount: ${data['total_amount']}');
        print('  Amount: ${data['amount']}');
        print('  Calculated Amount: ₹$amount');
        print('  Created At: ${data['created_at']}');
        print('  ---');
      }

      print('TOTAL CALCULATED: ₹$totalAmount');
      print('=== DEBUG COMPLETE ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }
}
