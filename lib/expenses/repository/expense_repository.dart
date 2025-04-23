import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

@Injectable(as: IExpenseRepository)
class ExpenseRepository extends IExpenseRepository {
  ExpenseRepository(super.firestore);

  @override
  FirebaseResult<ExpenseModel> addExpense({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> items,
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

        // Create expense document
        await expenseDoc.set({
          'id': expenseDoc.id,
          'name': name,
          'start_date': startDate,
          'end_date': endDate,
          'items': expenseItems,
          'total_amount': totalAmount,
          'created_at': now,
          'updated_at': now,
        });

        // Update dashboard stats - increment total expenses
        final statsRef = FirebaseFirestore.instance.dashboardStats.doc('stats');
        final statsDoc = await statsRef.get();

        if (!statsDoc.exists) {
          // Create initial stats document if it doesn't exist
          await statsRef.set({
            'total_members': 0,
            'total_expenses': totalAmount,
            'updated_at': now,
          });
        } else {
          // Increment total expenses amount
          final currentAmount = (statsDoc.data()?['total_expenses'] as num?)?.toDouble() ?? 0.0;
          await statsRef.update({
            'total_expenses': currentAmount + totalAmount,
            'updated_at': now,
          });
        }

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '💰 New expense added: $name (₹${totalAmount.toStringAsFixed(2)})',
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
          startDate: startDate.toString(),
          endDate: endDate.toString(),
          items: expenseItemModels,
          totalAmount: totalAmount,
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
}
