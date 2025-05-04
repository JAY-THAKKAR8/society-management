import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/expenses/view/add_expense_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class LineExpensePage extends StatefulWidget {
  final String lineNumber;
  final String lineName;

  const LineExpensePage({
    super.key,
    required this.lineNumber,
    required this.lineName,
  });

  @override
  State<LineExpensePage> createState() => _LineExpensePageState();
}

class _LineExpensePageState extends State<LineExpensePage> {
  final _repository = getIt<IExpenseRepository>();
  bool _isLoading = true;
  List<ExpenseModel> _expenses = [];
  Map<String, dynamic>? _statistics;
  String? _errorMessage;
  String _selectedFilter = 'This Month';

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
      // Get line-specific expenses
      final expensesResult = await _repository.getExpensesByLine(
        lineNumber: widget.lineNumber,
      );

      // Get date range based on selected filter
      final dateRange = _dateRanges[_selectedFilter]!();

      // Get statistics
      final statsResult = await _repository.getExpenseStatistics(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );

      expensesResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (expenses) {
          statsResult.fold(
            (failure) {
              setState(() {
                _expenses = expenses;
                _isLoading = false;
              });
            },
            (stats) {
              setState(() {
                _expenses = expenses;
                _statistics = stats;
                _isLoading = false;
              });
            },
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '${widget.lineName} Expenses',
        showDivider: true,
        onBackTap: () => context.pop(),
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

    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No expenses found for this line'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(const AddExpensePage()),
              child: const Text('Add Expense'),
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
            _buildCategoryBreakdown(),
            const SizedBox(height: 24),
            _buildExpenseList(),
            const SizedBox(height: 100), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _buildSummaryCards() {
    if (_statistics == null) {
      return const SizedBox.shrink();
    }

    final lineTotals = _statistics!['line_totals'] as Map<String, dynamic>? ?? {};
    final lineTotal = lineTotals[widget.lineName] as double? ?? 0.0;

    final totalAmount = _statistics!['total_amount'] as double? ?? 0.0;
    final percentage = totalAmount > 0 ? (lineTotal / totalAmount) * 100 : 0.0;

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
                    formatter.format(lineTotal),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Line Expenses',
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
                          Icons.pie_chart,
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
                    '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Of Total Expenses',
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

  Widget _buildCategoryBreakdown() {
    // Filter expenses by the selected date range
    final dateRange = _dateRanges[_selectedFilter]!();
    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

    final filteredExpenses = _expenses.where((expense) {
      if (expense.createdAt == null) return false;
      final expenseDate = DateTime.parse(expense.createdAt!);
      return expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate category totals
    final categoryTotals = <String, double>{};
    double totalAmount = 0;

    for (final expense in filteredExpenses) {
      final amount = expense.totalAmount ?? 0;
      totalAmount += amount;

      final categoryName = expense.categoryName ?? 'Uncategorized';
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + amount;
    }

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    // Sort categories by amount (highest first)
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ThemeAwareCard(
          useContainerColor: true,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sortedCategories.map((entry) {
                final categoryName = entry.key;
                final amount = entry.value;
                final percentage = (amount / totalAmount) * 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categoryName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            formatter.format(amount),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor:
                            ThemeUtils.isDarkMode(context) ? Colors.grey.withAlpha(50) : Colors.grey.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(categoryName),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );

    // Sort expenses by date (newest first)
    final sortedExpenses = List<ExpenseModel>.from(_expenses)
      ..sort((a, b) {
        final aDate = a.createdAt != null ? DateTime.parse(a.createdAt!) : DateTime(1900);
        final bDate = b.createdAt != null ? DateTime.parse(b.createdAt!) : DateTime(1900);
        return bDate.compareTo(aDate);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Line Expenses',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...sortedExpenses.map((expense) {
          final dateStr = expense.createdAt != null
              ? DateFormat('MMM d, yyyy').format(DateTime.parse(expense.createdAt!))
              : 'Unknown date';

          return ThemeAwareCard(
            margin: const EdgeInsets.only(bottom: 12),
            useContainerColor: true,
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // TODO: Navigate to expense details page
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ThemeUtils.getHighlightColor(context, _getCategoryColor(expense.categoryName)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.categoryName),
                      color: _getCategoryColor(expense.categoryName),
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
                  Text(
                    formatter.format(expense.totalAmount ?? 0),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(String? categoryName) {
    if (categoryName == null) return Colors.grey;

    // Check for known category names first
    switch (categoryName.toLowerCase()) {
      case 'maintenance':
        return Colors.blue;
      case 'utilities':
        return Colors.green;
      case 'security':
        return Colors.red;
      case 'events':
        return Colors.orange;
      case 'emergency':
        return Colors.purple;
      case 'infrastructure':
        return Colors.brown;
      case 'administrative':
        return Colors.teal;
    }

    // Fall back to hash-based color for unknown categories
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

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.receipt_long;

    switch (categoryName.toLowerCase()) {
      case 'maintenance':
        return Icons.build;
      case 'utilities':
        return Icons.electric_bolt;
      case 'security':
        return Icons.security;
      case 'events':
        return Icons.event;
      case 'emergency':
        return Icons.emergency;
      case 'infrastructure':
        return Icons.apartment;
      case 'administrative':
        return Icons.admin_panel_settings;
      default:
        return Icons.category;
    }
  }
}
