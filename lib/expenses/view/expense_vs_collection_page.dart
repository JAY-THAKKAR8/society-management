import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class ExpenseVsCollectionPage extends StatefulWidget {
  const ExpenseVsCollectionPage({super.key});

  @override
  State<ExpenseVsCollectionPage> createState() => _ExpenseVsCollectionPageState();
}

class _ExpenseVsCollectionPageState extends State<ExpenseVsCollectionPage> {
  final _expenseRepository = getIt<IExpenseRepository>();
  final _maintenanceRepository = getIt<IMaintenanceRepository>();
  bool _isLoading = true;
  double _totalExpense = 0;
  double _totalCollection = 0;
  List<Map<String, dynamic>> _monthlyData = [];
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
      final startDate = dateRange['start'] as DateTime;
      final endDate = dateRange['end'] as DateTime;

      // Get all expenses
      final expensesResult = await _expenseRepository.getAllExpenses();

      // Get active maintenance periods
      final periodsResult = await _maintenanceRepository.getActiveMaintenancePeriods();

      // Process expenses
      double totalExpense = 0;
      final monthlyExpenses = <String, double>{};

      expensesResult.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
          Utility.toast(message: failure.message);
        },
        (allExpenses) {
          // Filter expenses by date range and line
          final filteredExpenses = allExpenses.where((expense) {
            if (expense.createdAt == null) return false;
            final expenseDate = DateTime.parse(expense.createdAt!);

            final isInDateRange =
                expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate.add(const Duration(days: 1)));

            final isInSelectedLine = _selectedLine == null || expense.lineNumber == _selectedLine;

            return isInDateRange && isInSelectedLine;
          }).toList();

          // Calculate total expense
          for (final expense in filteredExpenses) {
            final amount = expense.totalAmount ?? 0;
            totalExpense += amount;

            // Group by month
            if (expense.createdAt != null) {
              final date = DateTime.parse(expense.createdAt!);
              final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
              monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + amount;
            }
          }

          // Process maintenance collections
          double totalCollection = 0;
          final monthlyCollections = <String, double>{};

          periodsResult.fold(
            (failure) {
              // Ignore failure, just set total to 0
            },
            (periods) {
              // For maintenance periods, we don't filter by line since periods apply to all lines
              // We'll filter the payments instead when calculating totals
              final filteredPeriods = periods;

              for (final period in filteredPeriods) {
                // Check if period is within date range
                if (period.startDate != null && period.endDate != null) {
                  final periodStartDate = DateTime.parse(period.startDate!);
                  final periodEndDate = DateTime.parse(period.endDate!);

                  // If period overlaps with selected date range
                  if (!(periodEndDate.isBefore(startDate) || periodStartDate.isAfter(endDate))) {
                    totalCollection += period.totalCollected;

                    // Group by month (using period end date)
                    final monthKey = '${periodEndDate.year}-${periodEndDate.month.toString().padLeft(2, '0')}';
                    monthlyCollections[monthKey] = (monthlyCollections[monthKey] ?? 0) + period.totalCollected;
                  }
                }
              }
            },
          );

          // Combine monthly data
          final allMonths = <String>{...monthlyExpenses.keys, ...monthlyCollections.keys};
          final monthlyData = allMonths.map((month) {
            return {
              'month': month,
              'expense': monthlyExpenses[month] ?? 0,
              'collection': monthlyCollections[month] ?? 0,
            };
          }).toList();

          // Sort by month
          monthlyData.sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));

          setState(() {
            _totalExpense = totalExpense;
            _totalCollection = totalCollection;
            _monthlyData = monthlyData;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Expense vs Collection',
        showDivider: true,
        onBackTap: () => context.pop(),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection(),
          const SizedBox(height: 24),
          _buildComparisonCard(),
          const SizedBox(height: 24),
          _buildMonthlyComparisonChart(),
          const SizedBox(height: 24),
          _buildMonthlyComparisonTable(),
        ],
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

  Widget _buildComparisonCard() {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final balance = _totalCollection - _totalExpense;
    final isPositive = balance >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeUtils.isDarkMode(context) ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildComparisonItem(
                      'Total Expenses',
                      _totalExpense,
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                  ),
                  Expanded(
                    child: _buildComparisonItem(
                      'Total Collection',
                      _totalCollection,
                      Colors.green,
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatter.format(balance.abs()),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _totalCollection > 0 ? (_totalExpense / _totalCollection).clamp(0.0, 1.0) : 0.0,
                backgroundColor: ThemeUtils.isDarkMode(context) ? Colors.grey.withAlpha(50) : Colors.grey.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _totalExpense > _totalCollection ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPositive
                    ? 'You have a surplus of ${formatter.format(balance)}'
                    : 'You have a deficit of ${formatter.format(balance.abs())}',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isPositive) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your society is financially healthy with more collections than expenses.',
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your society is spending more than it collects. Consider increasing collections or reducing expenses.',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonItem(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              formatter.format(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyComparisonChart() {
    if (_monthlyData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No data available for the selected period'),
        ),
      );
    }

    // Take last 6 months for better visualization
    final recentMonths = _monthlyData.length > 6 ? _monthlyData.sublist(_monthlyData.length - 6) : _monthlyData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Comparison',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _buildComparisonBarChart(recentMonths),
        ),
      ],
    );
  }

  Widget _buildComparisonBarChart(List<Map<String, dynamic>> monthlyData) {
    // Find the maximum value for scaling
    double maxValue = 0;
    for (final data in monthlyData) {
      final expense = data['expense'] as double;
      final collection = data['collection'] as double;
      final maxForMonth = expense > collection ? expense : collection;
      if (maxForMonth > maxValue) {
        maxValue = maxForMonth;
      }
    }

    // Add 10% padding to max value
    maxValue = maxValue * 1.1;

    final formatter = NumberFormat.compactCurrency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 30, left: 10, right: 10),
      decoration: BoxDecoration(
        color: ThemeUtils.isDarkMode(context) ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = (constraints.maxWidth - 40) / (monthlyData.length * 2) - 4;

          return Stack(
            children: [
              // Y-axis labels
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatter.format(maxValue),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      formatter.format(maxValue / 2),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '₹0',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Horizontal grid lines
              ...List.generate(3, (index) {
                final y = index * (constraints.maxHeight - 30) / 2;
                return Positioned(
                  left: 30,
                  top: y,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: ThemeUtils.isDarkMode(context) ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                  ),
                );
              }),

              // Legend
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    const Text('Expense'),
                    const SizedBox(width: 12),
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.green.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    const Text('Collection'),
                  ],
                ),
              ),

              // Bars
              Positioned(
                left: 40,
                right: 0,
                bottom: 30,
                top: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlyData.map((data) {
                    final monthKey = data['month'] as String;
                    final expense = data['expense'] as double;
                    final collection = data['collection'] as double;

                    final expenseHeight = (constraints.maxHeight - 50) * (expense / maxValue);
                    final collectionHeight = (constraints.maxHeight - 50) * (collection / maxValue);

                    // Parse month from format YYYY-MM
                    final parts = monthKey.split('-');
                    final monthName = parts.length > 1
                        ? DateFormat('MMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
                        : monthKey;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: barWidth * 2 + 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: barWidth,
                                height: expenseHeight,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: barWidth,
                                height: collectionHeight,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.7),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyComparisonTable() {
    if (_monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: ThemeUtils.isDarkMode(context) ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Table header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Month',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Expense',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Collection',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Balance',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Table rows
              ..._monthlyData.map((data) {
                final monthKey = data['month'] as String;
                final expense = data['expense'] as double;
                final collection = data['collection'] as double;
                final balance = collection - expense;
                final isPositive = balance >= 0;

                // Parse month from format YYYY-MM
                final parts = monthKey.split('-');
                final monthName = parts.length > 1
                    ? DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
                    : monthKey;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              monthName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatter.format(expense),
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatter.format(collection),
                              style: const TextStyle(
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatter.format(balance.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
              // Total row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatter.format(_totalExpense),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatter.format(_totalCollection),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatter.format((_totalCollection - _totalExpense).abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _totalCollection >= _totalExpense ? Colors.green : Colors.red,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
