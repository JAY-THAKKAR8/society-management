import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/expenses/view/add_expense_page.dart';
import 'package:society_management/expenses/view/expense_category_page.dart';
import 'package:society_management/expenses/view/expense_charts_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class ExpenseDashboardPage extends StatefulWidget {
  const ExpenseDashboardPage({super.key});

  @override
  State<ExpenseDashboardPage> createState() => _ExpenseDashboardPageState();
}

class _ExpenseDashboardPageState extends State<ExpenseDashboardPage> {
  final _repository = getIt<IExpenseRepository>();
  bool _isLoading = true;
  Map<String, dynamic>? _statistics;
  List<ExpenseModel> _recentExpenses = [];
  String? _errorMessage;
  String _selectedFilter = 'This Month';
  String? _selectedLine;

  final _dateRanges = {
    'This Month': () {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      return {
        'start': startOfMonth,
        'end': now,
      };
    },
    'Last Month': () {
      final now = DateTime.now();
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);
      return {
        'start': startOfLastMonth,
        'end': endOfLastMonth,
      };
    },
    'Last 3 Months': () {
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      return {
        'start': threeMonthsAgo,
        'end': now,
      };
    },
    'This Year': () {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      return {
        'start': startOfYear,
        'end': now,
      };
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get date range based on selected filter
      final dateRange = _dateRanges[_selectedFilter]!();

      // Get all expenses
      final expensesResult = await _repository.getAllExpenses();

      expensesResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (allExpenses) {
          // Filter expenses by date range
          final filteredByDate = allExpenses.where((expense) {
            if (expense.createdAt == null) return false;
            final expenseDate = DateTime.parse(expense.createdAt!);
            final startDate = dateRange['start'] as DateTime;
            final endDate = dateRange['end'] as DateTime;
            return expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();

          // Further filter by line if selected
          final filteredExpenses = _selectedLine == null
              ? filteredByDate
              : filteredByDate.where((e) => e.lineNumber == _selectedLine).toList();

          // Calculate statistics from filtered expenses
          final stats = _calculateStatistics(filteredExpenses);

          // Sort expenses by date (newest first) and take the 5 most recent
          final sortedExpenses = List<ExpenseModel>.from(filteredExpenses)
            ..sort((a, b) {
              final aDate = a.createdAt != null ? DateTime.parse(a.createdAt!) : DateTime(1900);
              final bDate = b.createdAt != null ? DateTime.parse(b.createdAt!) : DateTime(1900);
              return bDate.compareTo(aDate);
            });

          final recentExpenses = sortedExpenses.length > 5 ? sortedExpenses.sublist(0, 5) : sortedExpenses;

          setState(() {
            _statistics = stats;
            _recentExpenses = recentExpenses;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error loading data: $e');
    }
  }

  // Helper method to calculate statistics from filtered expenses
  Map<String, dynamic> _calculateStatistics(List<ExpenseModel> expenses) {
    double totalAmount = 0;
    final categoryTotals = <String, double>{};
    final lineTotals = <String, double>{};
    final monthlyTotals = <String, double>{};

    for (final expense in expenses) {
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
      'expense_count': expenses.length,
      'category_totals': categoryTotals,
      'line_totals': lineTotals,
      'monthly_totals': monthlyTotals,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Expense Dashboard',
        showDivider: true,
        onBackTap: () => context.pop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _navigateToChartsPage(),
            tooltip: 'View Charts',
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => context.push(const ExpenseCategoryPage()),
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(const AddExpensePage());
          if (mounted) {
            _loadData();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildRecentExpenses(),
            const SizedBox(height: 100), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedFilter,
            decoration: InputDecoration(
              labelText: 'Time Period',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: _dateRanges.keys.map((filter) {
              return DropdownMenuItem<String>(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != _selectedFilter) {
                setState(() {
                  _selectedFilter = value;
                });
                _loadData();
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String?>(
            value: _selectedLine,
            decoration: InputDecoration(
              labelText: 'Line',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: const [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('All Lines'),
              ),
              DropdownMenuItem<String?>(
                value: 'FIRST_LINE',
                child: Text('Line 1'),
              ),
              DropdownMenuItem<String?>(
                value: 'SECOND_LINE',
                child: Text('Line 2'),
              ),
              DropdownMenuItem<String?>(
                value: 'THIRD_LINE',
                child: Text('Line 3'),
              ),
              DropdownMenuItem<String?>(
                value: 'FOURTH_LINE',
                child: Text('Line 4'),
              ),
              DropdownMenuItem<String?>(
                value: 'FIFTH_LINE',
                child: Text('Line 5'),
              ),
            ],
            onChanged: (value) {
              if (value != _selectedLine) {
                setState(() {
                  _selectedLine = value;
                });
                _loadData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    if (_statistics == null) {
      return const SizedBox.shrink();
    }

    final totalAmount = _statistics!['total_amount'] as double? ?? 0.0;
    final expenseCount = _statistics!['expense_count'] as int? ?? 0;

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );

    return Row(
      children: [
        Expanded(
          child: ThemeAwareCard(
            useContainerColor: true,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeUtils.getHighlightColor(context, Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _selectedFilter,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formatter.format(totalAmount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ThemeAwareCard(
            useContainerColor: true,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeUtils.getHighlightColor(context, Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _selectedFilter,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    expenseCount.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expense Count',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToChartsPage() {
    // Navigate to the charts page
    context.push(const ExpenseChartsPage());
  }

  Widget _buildRecentExpenses() {
    if (_recentExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Expenses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to expense list page - for now, we'll just show a message
                Utility.toast(message: 'Expense list page will be implemented soon');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_recentExpenses.length, (index) {
          final expense = _recentExpenses[index];
          final dateStr = expense.createdAt != null
              ? DateFormat('MMM d, yyyy').format(DateTime.parse(expense.createdAt!))
              : 'Unknown date';

          return ThemeAwareCard(
            margin: const EdgeInsets.only(bottom: 12),
            useContainerColor: true,
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navigate to expense details page - for now, we'll just show a message
              Utility.toast(message: 'Expense details page will be implemented soon');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ThemeUtils.getHighlightColor(
                          context, _getCategoryColor(expense.categoryName ?? 'Uncategorized')),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: _getCategoryColor(expense.categoryName ?? 'Uncategorized'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.name ?? 'Unnamed Expense',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          expense.categoryName ?? 'Uncategorized',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatter.format(expense.totalAmount ?? 0),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (expense.lineNumber != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ThemeUtils.getHighlightColor(context, _getLineColor(expense.lineName ?? '')),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            expense.lineName ?? 'Unknown Line',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getLineColor(expense.lineName ?? ''),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(String categoryName) {
    // This is a simple hash function to generate consistent colors for categories
    final hash = categoryName.hashCode.abs() % 5;
    switch (hash) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getLineColor(String lineName) {
    // First check for exact matches
    switch (lineName) {
      case 'Line 1':
        return Colors.blue;
      case 'Line 2':
        return Colors.green;
      case 'Line 3':
        return Colors.orange;
      case 'Line 4':
        return Colors.purple;
      case 'Line 5':
        return Colors.red;
      case 'Common':
        return Colors.teal;
      case 'FIRST_LINE':
        return Colors.blue;
      case 'SECOND_LINE':
        return Colors.green;
      case 'THIRD_LINE':
        return Colors.orange;
      case 'FOURTH_LINE':
        return Colors.purple;
      case 'FIFTH_LINE':
        return Colors.red;
    }

    // Then check for partial matches
    if (lineName.contains('1') || lineName.toLowerCase().contains('first')) {
      return Colors.blue;
    } else if (lineName.contains('2') || lineName.toLowerCase().contains('second')) {
      return Colors.green;
    } else if (lineName.contains('3') || lineName.toLowerCase().contains('third')) {
      return Colors.orange;
    } else if (lineName.contains('4') || lineName.toLowerCase().contains('fourth')) {
      return Colors.purple;
    } else if (lineName.contains('5') || lineName.toLowerCase().contains('fifth')) {
      return Colors.red;
    } else if (lineName.toLowerCase().contains('common')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }
}
