import 'package:flutter/material.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/expenses/widgets/expense_form.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final isLoading = ValueNotifier<bool>(false);

  @override
  void dispose() {
    isLoading.dispose();
    super.dispose();
  }

  Future<void> _submitExpense({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<ExpenseItemModel> items,
  }) async {
    isLoading.value = true;

    final itemsData = items
        .map((item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
            })
        .toList();

    final response = await getIt<IExpenseRepository>().addExpense(
      name: name,
      startDate: startDate,
      endDate: endDate,
      items: itemsData,
    );

    response.fold(
      (failure) {
        isLoading.value = false;
        Utility.toast(message: failure.message);
      },
      (expense) {
        isLoading.value = false;
        Utility.toast(message: 'Expense added successfully');
        // You can add a refresh action here if needed
        // context.read<RefreshCubit>().refreshExpenses();
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Add New Expense',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder(
          valueListenable: isLoading,
          builder: (context, loading, _) {
            return ExpenseForm(
              isLoading: loading,
              onSubmit: _submitExpense,
            );
          },
        ),
      ),
    );
  }
}
