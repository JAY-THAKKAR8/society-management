import 'package:flutter/material.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/expenses/widgets/expense_form.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
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
  final _repository = getIt<IExpenseRepository>();

  // Simplified approach with predefined categories
  String? _selectedCategoryId;
  String? _selectedLine;
  ExpensePriority _selectedPriority = ExpensePriority.medium;

  // Predefined categories with their colors
  final Map<String, Map<String, dynamic>> _predefinedCategories = {
    'maintenance': {
      'name': 'Maintenance',
      'color': Colors.blue,
      'icon': Icons.build,
    },
    'utilities': {
      'name': 'Utilities',
      'color': Colors.green,
      'icon': Icons.electric_bolt,
    },
    'security': {
      'name': 'Security',
      'color': Colors.red,
      'icon': Icons.security,
    },
    'events': {
      'name': 'Events',
      'color': Colors.orange,
      'icon': Icons.event,
    },
    'emergency': {
      'name': 'Emergency',
      'color': Colors.purple,
      'icon': Icons.emergency,
    },
    'other': {
      'name': 'Other',
      'color': Colors.grey,
      'icon': Icons.category,
    },
  };

  @override
  void initState() {
    super.initState();
    // Set default category
    _selectedCategoryId = 'maintenance';
  }

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
    String? description,
  }) async {
    isLoading.value = true;

    final itemsData = items
        .map((item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
            })
        .toList();

    final response = await _repository.addExpense(
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      items: itemsData,
      categoryId: _selectedCategoryId,
      lineNumber: _selectedLine,
      priority: _selectedPriority,
    );

    response.fold(
      (failure) {
        isLoading.value = false;
        Utility.toast(message: failure.message);
      },
      (expense) {
        isLoading.value = false;
        Utility.toast(message: 'Expense added successfully');
        context.pop();
      },
    );
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _onLineSelected(String? line) {
    setState(() {
      _selectedLine = line;
    });
  }

  void _onPrioritySelected(ExpensePriority priority) {
    setState(() {
      _selectedPriority = priority;
    });
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category selector
                _buildCategorySelector(),

                // Line selector
                const SizedBox(height: 16),
                _buildLineSelector(),

                // Priority selector
                const SizedBox(height: 16),
                Text(
                  'Priority',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildPrioritySelector(),

                const SizedBox(height: 24),

                // Original expense form
                ExpenseForm(
                  isLoading: loading,
                  onSubmit: _submitExpense,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedCategories.entries.map((entry) {
            final categoryId = entry.key;
            final category = entry.value;
            final isSelected = _selectedCategoryId == categoryId;

            return InkWell(
              onTap: () => _onCategorySelected(categoryId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ThemeUtils.getHighlightColor(context, category['color'])
                      : ThemeUtils.isDarkMode(context)
                          ? Colors.grey.withAlpha(50)
                          : Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: category['color'], width: 2) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'],
                      color: isSelected ? category['color'] : null,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category['name'],
                      style: TextStyle(
                        color: isSelected ? category['color'] : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildLineOption(null, 'Common (All Lines)', Colors.teal),
            _buildLineOption('FIRST_LINE', 'Line 1', Colors.blue),
            _buildLineOption('SECOND_LINE', 'Line 2', Colors.green),
            _buildLineOption('THIRD_LINE', 'Line 3', Colors.orange),
            _buildLineOption('FOURTH_LINE', 'Line 4', Colors.purple),
            _buildLineOption('FIFTH_LINE', 'Line 5', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildLineOption(String? lineNumber, String label, Color color) {
    final isSelected = _selectedLine == lineNumber;

    return InkWell(
      onTap: () => _onLineSelected(lineNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeUtils.getHighlightColor(context, color)
              : ThemeUtils.isDarkMode(context)
                  ? Colors.grey.withAlpha(50)
                  : Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPriorityOption(ExpensePriority.low, 'Low', Colors.green),
        _buildPriorityOption(ExpensePriority.medium, 'Medium', Colors.blue),
        _buildPriorityOption(ExpensePriority.high, 'High', Colors.orange),
        _buildPriorityOption(ExpensePriority.critical, 'Critical', Colors.red),
      ],
    );
  }

  Widget _buildPriorityOption(ExpensePriority priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;

    return InkWell(
      onTap: () => _onPrioritySelected(priority),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeUtils.getHighlightColor(context, color)
              : ThemeUtils.isDarkMode(context)
                  ? Colors.grey.withAlpha(50)
                  : Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
