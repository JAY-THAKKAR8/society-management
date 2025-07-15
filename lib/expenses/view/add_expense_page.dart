import 'package:cloud_firestore/cloud_firestore.dart';
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
  final ExpenseModel? expenseToEdit; // Optional expense for editing

  const AddExpensePage({
    super.key,
    this.expenseToEdit,
  });

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

  // Check if we're in edit mode
  bool get isEditMode => widget.expenseToEdit != null;

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
    _initializeFormForEditing();
  }

  // Initialize form fields when editing an expense
  void _initializeFormForEditing() {
    if (isEditMode && widget.expenseToEdit != null) {
      final expense = widget.expenseToEdit!;

      // Set category based on expense category name
      _selectedCategoryId = _findCategoryIdByName(expense.categoryName);

      // Set line
      _selectedLine = expense.lineName;

      // Set priority
      _selectedPriority = expense.priority ?? ExpensePriority.medium;
    } else {
      // Set default category for new expense
      _selectedCategoryId = 'maintenance';
    }
  }

  // Helper method to find category ID by name
  String? _findCategoryIdByName(String? categoryName) {
    if (categoryName == null) return null;

    for (final entry in _predefinedCategories.entries) {
      if (entry.value['name'] == categoryName) {
        return entry.key;
      }
    }
    return null;
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
      (expense) async {
        isLoading.value = false;

        // Force refresh dashboard stats after adding expense
        try {
          // Calculate total from expenses collection and update all dashboards
          await _refreshDashboardStats();
        } catch (e) {
          print('Error refreshing dashboard stats: $e');
        }

        Utility.toast(message: 'Expense added successfully');
        if (mounted) {
          context.pop();
        }
      },
    );
  }

  // Refresh dashboard stats after adding expense
  Future<void> _refreshDashboardStats() async {
    try {
      // Import Firebase directly since we can't import the service
      final firestore = FirebaseFirestore.instance;

      // Calculate total expenses from expenses collection
      final expensesSnapshot = await firestore.collection('expenses').get();
      double totalExpenses = 0.0;

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        // Try multiple field names that might contain the amount
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpenses += amount;
      }

      final now = Timestamp.fromDate(DateTime.now());

      // Update admin dashboard stats
      await firestore.collection('admin_dashboard_stats').doc('stats').update({
        'total_expenses': totalExpenses,
        'updated_at': now,
      });

      // Update line head dashboard stats for all lines
      final lineStatsSnapshot = await firestore.collection('line_head_dashboard_stats').get();
      for (final doc in lineStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      // Update user dashboard stats for all users
      final userStatsSnapshot = await firestore.collection('user_dashboard_stats').get();
      for (final doc in userStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      print('Dashboard stats refreshed with total: ₹$totalExpenses'); // Debug log
    } catch (e) {
      print('Error refreshing dashboard stats: $e');
    }
  }

  // Debug method to check expenses and dashboard stats
  Future<void> _debugExpensesAndDashboard() async {
    try {
      print('=== DEBUGGING EXPENSES & DASHBOARD ===');

      final firestore = FirebaseFirestore.instance;

      // 1. Check expenses collection
      final expensesSnapshot = await firestore.collection('expenses').get();
      print('📊 EXPENSES COLLECTION:');
      print('Total expense documents: ${expensesSnapshot.docs.length}');

      double totalFromExpenses = 0.0;
      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalFromExpenses += amount;

        print(
            '  - ${data['name'] ?? 'Unknown'}: ₹$amount (total_amount: ${data['total_amount']}, amount: ${data['amount']})');
      }
      print('📊 CALCULATED TOTAL FROM EXPENSES: ₹$totalFromExpenses');

      // 2. Check admin dashboard stats
      final adminStatsDoc = await firestore.collection('admin_dashboard_stats').doc('stats').get();
      print('\n📈 ADMIN DASHBOARD STATS:');
      print('Document exists: ${adminStatsDoc.exists}');

      if (adminStatsDoc.exists) {
        final data = adminStatsDoc.data()!;
        print('  - total_expenses: ${data['total_expenses']}');
        print('  - total_members: ${data['total_members']}');
        print('  - updated_at: ${data['updated_at']}');
      } else {
        print('  - Admin dashboard stats document does not exist!');
      }

      // 3. Check line head dashboard stats
      final lineStatsSnapshot = await firestore.collection('line_head_dashboard_stats').get();
      print('\n📊 LINE HEAD DASHBOARD STATS:');
      print('Total line stats documents: ${lineStatsSnapshot.docs.length}');

      for (final doc in lineStatsSnapshot.docs) {
        final data = doc.data();
        print('  - Line ${doc.id}: total_expenses = ${data['total_expenses']}');
      }

      // 4. Check user dashboard stats
      final userStatsSnapshot = await firestore.collection('user_dashboard_stats').get();
      print('\n👥 USER DASHBOARD STATS:');
      print('Total user stats documents: ${userStatsSnapshot.docs.length}');

      for (final doc in userStatsSnapshot.docs) {
        final data = doc.data();
        print('  - User ${doc.id}: total_expenses = ${data['total_expenses']}');
      }

      print('\n=== DEBUG COMPLETE ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  // Force update dashboard stats (create if doesn't exist)
  Future<void> _forceUpdateDashboardStats() async {
    try {
      print('=== FORCE UPDATING DASHBOARD STATS ===');

      final firestore = FirebaseFirestore.instance;

      // Calculate total expenses from expenses collection
      final expensesSnapshot = await firestore.collection('expenses').get();
      double totalExpenses = 0.0;

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalExpenses += amount;
      }

      final now = Timestamp.fromDate(DateTime.now());

      // Force create/update admin dashboard stats
      await firestore.collection('admin_dashboard_stats').doc('stats').set({
        'total_members': 0,
        'total_expenses': totalExpenses,
        'maintenance_collected': 0.0,
        'maintenance_pending': 0.0,
        'active_maintenance': 0,
        'fully_paid': 0,
        'updated_at': now,
      });

      print('✅ Admin dashboard stats created/updated with total: ₹$totalExpenses');

      // Update line head dashboard stats for all lines
      final lineStatsSnapshot = await firestore.collection('line_head_dashboard_stats').get();
      for (final doc in lineStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      // Update user dashboard stats for all users
      final userStatsSnapshot = await firestore.collection('user_dashboard_stats').get();
      for (final doc in userStatsSnapshot.docs) {
        await doc.reference.update({
          'total_expenses': totalExpenses,
          'updated_at': now,
        });
      }

      print('✅ All dashboard stats force updated with total: ₹$totalExpenses');
      print('=== FORCE UPDATE COMPLETE ===');
    } catch (e) {
      print('Error force updating dashboard stats: $e');
    }
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
        title: isEditMode ? 'Edit Expense' : 'Add New Expense',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await _debugExpensesAndDashboard();
              Utility.toast(message: 'Debug info printed to console');
            },
            tooltip: 'Debug Expenses & Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _forceUpdateDashboardStats();
              Utility.toast(message: 'Dashboard stats force updated!');
            },
            tooltip: 'Force Update Dashboard',
          ),
        ],
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
                  expenseToEdit: widget.expenseToEdit, // Pass expense for editing
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
