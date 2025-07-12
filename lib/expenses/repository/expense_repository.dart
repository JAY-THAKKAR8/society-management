import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/expenses/model/expense_category_model.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

@Injectable(as: IExpenseRepository)
class ExpenseRepository extends IExpenseRepository {
  ExpenseRepository(super.firestore);

  // Add a new collection reference for categories
  CollectionReference get _categoriesCollection => FirebaseFirestore.instance.collection('expense_categories');

  @override
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
  }) {
    return Result<ExpenseModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final expenseCollection = FirebaseFirestore.instance.expenses;
        final expenseDoc = expenseCollection.doc();

        // Calculate total amount
        double totalAmount = 0;
        final expenseItems = items.map((item) {
          final price = item['price'] as double? ?? 0;
          totalAmount += price;
          return {
            'id': item['id'] ?? expenseDoc.id,
            'name': item['name'],
            'price': price,
          };
        }).toList();

        // Simplified category handling
        // Just use a simple category name string instead of a complex object
        String? categoryName;
        if (categoryId != null) {
          // Map common category IDs to readable names
          switch (categoryId) {
            case 'maintenance':
              categoryName = 'Maintenance';
              break;
            case 'utilities':
              categoryName = 'Utilities';
              break;
            case 'security':
              categoryName = 'Security';
              break;
            case 'events':
              categoryName = 'Events';
              break;
            case 'emergency':
              categoryName = 'Emergency';
              break;
            default:
              categoryName = 'Other';
          }
        }

        // Get line name if line number is provided
        String? lineName;
        if (lineNumber != null) {
          switch (lineNumber) {
            case 'FIRST_LINE':
              lineName = 'Line 1';
              break;
            case 'SECOND_LINE':
              lineName = 'Line 2';
              break;
            case 'THIRD_LINE':
              lineName = 'Line 3';
              break;
            case 'FOURTH_LINE':
              lineName = 'Line 4';
              break;
            case 'FIFTH_LINE':
              lineName = 'Line 5';
              break;
            default:
              lineName = 'Unknown Line';
          }
        }

        // Create the expense document
        final expenseData = {
          'id': expenseDoc.id,
          'name': name,
          'description': description,
          'start_date': Timestamp.fromDate(startDate),
          'end_date': Timestamp.fromDate(endDate),
          'items': expenseItems,
          'total_amount': totalAmount,
          'category_id': categoryId,
          'category_name': categoryName,
          'line_number': lineNumber,
          'line_name': lineName,
          'vendor_name': vendorName,
          'receipt_url': receiptUrl,
          'priority': priority.toString().split('.').last,
          'added_by': 'admin', // You would get this from auth
          'added_by_name': 'Admin', // You would get this from auth
          'created_at': now,
          'updated_at': now,
        };

        await expenseDoc.set(expenseData);

        // Update dashboard stats - increment total expenses in ALL dashboard collections
        await _updateAllDashboardStats(totalAmount);

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        final activityMessage = lineNumber != null
            ? '💰 New expense added for $lineName: $name (₹${totalAmount.toStringAsFixed(2)})'
            : '💰 New common expense added: $name (₹${totalAmount.toStringAsFixed(2)})';

        await activityDoc.set({
          'id': activityDoc.id,
          'message': activityMessage,
          'type': 'expense',
          'timestamp': now,
        });

        final expenseItemModels = expenseItems
            .map((item) => ExpenseItemModel(
                  id: item['id'] as String?,
                  name: item['name'] as String?,
                  price: item['price'] as double?,
                ))
            .toList();

        return ExpenseModel(
          id: expenseDoc.id,
          name: name,
          description: description,
          startDate: startDate.toString(),
          endDate: endDate.toString(),
          items: expenseItemModels,
          totalAmount: totalAmount,
          categoryId: categoryId,
          categoryName: categoryName,
          lineNumber: lineNumber,
          lineName: lineName,
          vendorName: vendorName,
          receiptUrl: receiptUrl,
          priority: priority,
          addedBy: 'admin', // You would get this from auth
          addedByName: 'Admin', // You would get this from auth
          createdAt: now.toDate().toString(),
          updatedAt: now.toDate().toString(),
        );
      },
    );
  }

  @override
  FirebaseResult<List<ExpenseModel>> getAllExpenses() {
    return Result<List<ExpenseModel>>().tryCatch(
      run: () async {
        final expenses = await FirebaseFirestore.instance.expenses.get();
        final expenseModels = expenses.docs.map((e) => ExpenseModel.fromJson(e.data())).toList();
        return expenseModels;
      },
    );
  }

  @override
  FirebaseResult<ExpenseModel> getExpense({required String expenseId}) {
    return Result<ExpenseModel>().tryCatch(
      run: () async {
        final expenseCollection = FirebaseFirestore.instance.expenses;
        final expenseDoc = await expenseCollection.doc(expenseId).get();

        if (!expenseDoc.exists) {
          throw Exception('Expense not found');
        }
        return ExpenseModel.fromJson(expenseDoc.data()!);
      },
    );
  }

  @override
  FirebaseResult<void> deleteExpense({required String expenseId}) {
    return Result<void>().tryCatch(
      run: () async {
        final expenseCollection = FirebaseFirestore.instance.expenses;
        final expenseDoc = await expenseCollection.doc(expenseId).get();

        if (!expenseDoc.exists) {
          throw Exception('Expense not found');
        }

        await expenseCollection.doc(expenseId).delete();
      },
    );
  }

  @override
  FirebaseResult<List<ExpenseCategoryModel>> getAllCategories() {
    return Result<List<ExpenseCategoryModel>>().tryCatch(
      run: () async {
        final categories = await _categoriesCollection.get();
        final categoryModels =
            categories.docs.map((e) => ExpenseCategoryModel.fromJson(e.data() as Map<String, dynamic>)).toList();
        return categoryModels;
      },
    );
  }

  @override
  FirebaseResult<ExpenseCategoryModel> addCategory({
    required String name,
    String? description,
    String? iconName,
    String? colorHex,
    bool isCommonExpense = true,
    bool isRecurring = false,
  }) {
    return Result<ExpenseCategoryModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final categoryDoc = _categoriesCollection.doc();

        final categoryData = {
          'id': categoryDoc.id,
          'name': name,
          'description': description,
          'icon_name': iconName,
          'color_hex': colorHex,
          'is_common_expense': isCommonExpense,
          'is_recurring': isRecurring,
          'created_at': now,
          'updated_at': now,
        };

        await categoryDoc.set(categoryData);

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '📋 New expense category added: $name',
          'type': 'expense_category',
          'timestamp': now,
        });

        return ExpenseCategoryModel(
          id: categoryDoc.id,
          name: name,
          description: description,
          iconName: iconName,
          colorHex: colorHex,
          isCommonExpense: isCommonExpense,
          isRecurring: isRecurring,
          createdAt: now.toDate().toString(),
          updatedAt: now.toDate().toString(),
        );
      },
    );
  }

  @override
  FirebaseResult<ExpenseCategoryModel> getCategory({required String categoryId}) {
    return Result<ExpenseCategoryModel>().tryCatch(
      run: () async {
        final categoryDoc = await _categoriesCollection.doc(categoryId).get();

        if (!categoryDoc.exists) {
          throw Exception('Category not found');
        }

        return ExpenseCategoryModel.fromJson(categoryDoc.data() as Map<String, dynamic>);
      },
    );
  }

  @override
  FirebaseResult<void> deleteCategory({required String categoryId}) {
    return Result<void>().tryCatch(
      run: () async {
        final categoryDoc = await _categoriesCollection.doc(categoryId).get();

        if (!categoryDoc.exists) {
          throw Exception('Category not found');
        }

        // Check if any expenses use this category
        final expenses =
            await FirebaseFirestore.instance.expenses.where('category_id', isEqualTo: categoryId).limit(1).get();

        if (expenses.docs.isNotEmpty) {
          throw Exception('Cannot delete category that is used by expenses');
        }

        await _categoriesCollection.doc(categoryId).delete();
      },
    );
  }

  @override
  FirebaseResult<List<ExpenseModel>> getExpensesByLine({required String lineNumber}) {
    return Result<List<ExpenseModel>>().tryCatch(
      run: () async {
        final expenses = await FirebaseFirestore.instance.expenses.where('line_number', isEqualTo: lineNumber).get();

        final expenseModels = expenses.docs.map((e) => ExpenseModel.fromJson(e.data())).toList();
        return expenseModels;
      },
    );
  }

  @override
  FirebaseResult<Map<String, dynamic>> getExpenseStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Result<Map<String, dynamic>>().tryCatch(
      run: () async {
        // Default to last 30 days if no dates provided
        final effectiveStartDate = startDate ?? DateTime.now().subtract(const Duration(days: 30));
        final effectiveEndDate = endDate ?? DateTime.now();

        final startTimestamp = Timestamp.fromDate(effectiveStartDate);
        final endTimestamp = Timestamp.fromDate(effectiveEndDate);

        // Get all expenses in the date range
        final expenses = await FirebaseFirestore.instance.expenses
            .where('created_at', isGreaterThanOrEqualTo: startTimestamp)
            .where('created_at', isLessThanOrEqualTo: endTimestamp)
            .get();

        final expenseModels = expenses.docs.map((e) => ExpenseModel.fromJson(e.data())).toList();

        // Calculate statistics
        double totalAmount = 0;
        final categoryTotals = <String, double>{};
        final lineTotals = <String, double>{};
        final monthlyTotals = <String, double>{};

        for (final expense in expenseModels) {
          final amount = expense.totalAmount ?? 0;
          totalAmount += amount;

          // Category totals
          final categoryName = expense.categoryName ?? 'Uncategorized';
          categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + amount;

          // Line totals
          if (expense.lineNumber != null) {
            final lineName = expense.lineName ?? expense.lineNumber!;
            lineTotals[lineName] = (lineTotals[lineName] ?? 0) + amount;
          } else {
            lineTotals['Common'] = (lineTotals['Common'] ?? 0) + amount;
          }

          // Monthly totals
          if (expense.createdAt != null) {
            final date = DateTime.parse(expense.createdAt!);
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
          }
        }

        return {
          'total_amount': totalAmount,
          'expense_count': expenseModels.length,
          'category_totals': categoryTotals,
          'line_totals': lineTotals,
          'monthly_totals': monthlyTotals,
          'start_date': effectiveStartDate.toIso8601String(),
          'end_date': effectiveEndDate.toIso8601String(),
        };
      },
    );
  }

  // Update all dashboard stats collections when expense is added
  Future<void> _updateAllDashboardStats(double amount) async {
    try {
      final now = Timestamp.now();

      // Calculate total expenses from expenses collection
      final expensesSnapshot = await FirebaseFirestore.instance.collection('expenses').get();
      double totalExpenses = 0.0;

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        // Try multiple field names that might contain the amount
        final expenseAmount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpenses += expenseAmount;
      }

      // Update admin dashboard stats
      final adminStatsRef = FirebaseFirestore.instance.collection('admin_dashboard_stats').doc('stats');
      final adminStatsDoc = await adminStatsRef.get();
      print('Updated all dashboard stats with total expenses 1111: ₹$totalExpenses');

      if (adminStatsDoc.exists) {
        print('Updated all dashboard stats with total expenses 2222: ₹$totalExpenses');

        await adminStatsRef.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      } else {
        // Create initial admin stats if doesn't exist
        await adminStatsRef.set({
          'total_members': 0,
          'total_expenses': totalExpenses,
          'maintenance_collected': 0.0,
          'maintenance_pending': 0.0,
          'active_maintenance': 0,
          'fully_paid': 0,
          'updated_at': now,
        });
      }

      // Update line head dashboard stats for all lines
      final lineStatsSnapshot = await FirebaseFirestore.instance.collection('line_head_dashboard_stats').get();
      for (final doc in lineStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      // Update user dashboard stats for all users
      final userStatsSnapshot = await FirebaseFirestore.instance.collection('user_dashboard_stats').get();
      for (final doc in userStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      print('Updated all dashboard stats with total expenses: ₹$totalExpenses'); // Debug log
    } catch (e) {
      print('Error updating dashboard stats: $e');
    }
  }
}
