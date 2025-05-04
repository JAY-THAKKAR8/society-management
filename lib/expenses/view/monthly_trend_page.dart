import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class MonthlyTrendPage extends StatefulWidget {
  const MonthlyTrendPage({super.key});

  @override
  State<MonthlyTrendPage> createState() => _MonthlyTrendPageState();
}

class _MonthlyTrendPageState extends State<MonthlyTrendPage> {
  final _repository = getIt<IExpenseRepository>();
  bool _isLoading = true;
  Map<String, dynamic>? _statistics;
  List<MapEntry<String, dynamic>> _monthlyData = [];
  String? _errorMessage;
  String _selectedFilter = 'This Year';
  String? _selectedLine;
  String _chartType = 'bar'; // 'bar' or 'line'

  final _dateRanges = {
    'Last 3 Months': () {
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      return {
        'start': threeMonthsAgo,
        'end': now,
      };
    },
    'Last 6 Months': () {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
      return {
        'start': sixMonthsAgo,
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
    'Last Year': () {
      final now = DateTime.now();
      final startOfLastYear = DateTime(now.year - 1, 1, 1);
      final endOfLastYear = DateTime(now.year - 1, 12, 31);
      return {
        'start': startOfLastYear,
        'end': endOfLastYear,
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

      // Get all expenses first
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
          
          // Get monthly data
          final monthlyTotals = stats['monthly_totals'] as Map<String, dynamic>? ?? {};
          
          // Sort months chronologically
          final sortedMonths = monthlyTotals.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          setState(() {
            _statistics = stats;
            _monthlyData = sortedMonths;
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
    final monthlyTotals = <String, double>{};
    final categoryMonthlyTotals = <String, Map<String, double>>{};

    for (final expense in expenses) {
      final amount = expense.totalAmount ?? 0;
      totalAmount += amount;

      // Monthly totals
      if (expense.createdAt != null) {
        final date = DateTime.parse(expense.createdAt!);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
        
        // Category monthly totals
        final categoryName = expense.categoryName ?? 'Uncategorized';
        if (!categoryMonthlyTotals.containsKey(categoryName)) {
          categoryMonthlyTotals[categoryName] = {};
        }
        categoryMonthlyTotals[categoryName]![monthKey] = 
            (categoryMonthlyTotals[categoryName]![monthKey] ?? 0) + amount;
      }
    }

    return {
      'total_amount': totalAmount,
      'expense_count': expenses.length,
      'monthly_totals': monthlyTotals,
      'category_monthly_totals': categoryMonthlyTotals,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Monthly Expense Trend',
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
          _buildChartTypeSelector(),
          const SizedBox(height: 24),
          _buildMonthlyTrendChart(),
          const SizedBox(height: 24),
          _buildMonthlyTrendTable(),
          const SizedBox(height: 24),
          _buildMonthlyStatistics(),
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

  Widget _buildChartTypeSelector() {
    return Row(
      children: [
        const Text('Chart Type:'),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Bar Chart'),
          selected: _chartType == 'bar',
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _chartType = 'bar';
              });
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Line Chart'),
          selected: _chartType == 'line',
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _chartType = 'line';
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendChart() {
    if (_monthlyData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No expense data available for the selected period'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Expense Trend',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _chartType == 'bar' 
              ? _buildBarChart() 
              : _buildLineChart(),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    // Find the maximum value for scaling
    double maxValue = 0;
    for (final entry in _monthlyData) {
      final value = entry.value as double;
      if (value > maxValue) {
        maxValue = value;
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
        color: ThemeUtils.isDarkMode(context) 
            ? Colors.grey.shade800.withOpacity(0.3) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = (constraints.maxWidth - 40) / _monthlyData.length - 10;
          
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
                    color: ThemeUtils.isDarkMode(context) 
                        ? Colors.grey.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.3),
                  ),
                );
              }),
              
              // Bars
              Positioned(
                left: 40,
                right: 0,
                bottom: 30,
                top: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _monthlyData.map((entry) {
                    final monthKey = entry.key;
                    final amount = entry.value as double;
                    final percentage = maxValue > 0 ? amount / maxValue : 0;
                    final barHeight = (constraints.maxHeight - 30) * percentage;
                    
                    // Parse month from format YYYY-MM
                    final parts = monthKey.split('-');
                    final monthName = parts.length > 1 
                        ? DateFormat('MMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1]))) 
                        : monthKey;
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: barWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

  Widget _buildLineChart() {
    // Find the maximum value for scaling
    double maxValue = 0;
    for (final entry in _monthlyData) {
      final value = entry.value as double;
      if (value > maxValue) {
        maxValue = value;
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
        color: ThemeUtils.isDarkMode(context) 
            ? Colors.grey.shade800.withOpacity(0.3) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                    color: ThemeUtils.isDarkMode(context) 
                        ? Colors.grey.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.3),
                  ),
                );
              }),
              
              // Line chart
              Positioned(
                left: 40,
                right: 0,
                bottom: 30,
                top: 0,
                child: CustomPaint(
                  size: Size(constraints.maxWidth - 40, constraints.maxHeight - 30),
                  painter: LineChartPainter(
                    data: _monthlyData,
                    maxValue: maxValue,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              
              // X-axis labels
              Positioned(
                left: 40,
                right: 0,
                bottom: 0,
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _monthlyData.map((entry) {
                    final monthKey = entry.key;
                    
                    // Parse month from format YYYY-MM
                    final parts = monthKey.split('-');
                    final monthName = parts.length > 1 
                        ? DateFormat('MMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1]))) 
                        : monthKey;
                    
                    return Text(
                      monthName,
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildMonthlyTrendTable() {
    if (_monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final totalAmount = _statistics!['total_amount'] as double? ?? 0.0;

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
            color: ThemeUtils.isDarkMode(context) 
                ? Colors.grey.shade800.withOpacity(0.3) 
                : Colors.grey.shade100,
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
                        'Amount',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Percentage',
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
              ..._monthlyData.map((entry) {
                final monthKey = entry.key;
                final amount = entry.value as double;
                final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0;
                
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
                              formatter.format(amount),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }).toList(),
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
                        formatter.format(totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: Text(
                        '100%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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

  Widget _buildMonthlyStatistics() {
    if (_monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    // Calculate statistics
    double totalAmount = 0;
    double maxAmount = 0;
    double minAmount = double.infinity;
    String maxMonth = '';
    String minMonth = '';
    
    for (final entry in _monthlyData) {
      final amount = entry.value as double;
      totalAmount += amount;
      
      if (amount > maxAmount) {
        maxAmount = amount;
        maxMonth = entry.key;
      }
      
      if (amount < minAmount) {
        minAmount = amount;
        minMonth = entry.key;
      }
    }
    
    final avgAmount = _monthlyData.isNotEmpty ? totalAmount / _monthlyData.length : 0;
    
    // Format month names
    String formatMonthName(String monthKey) {
      final parts = monthKey.split('-');
      return parts.length > 1 
          ? DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1]))) 
          : monthKey;
    }
    
    final maxMonthName = formatMonthName(maxMonth);
    final minMonthName = formatMonthName(minMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeUtils.isDarkMode(context) 
                ? Colors.grey.shade800.withOpacity(0.3) 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatItem(
                'Average Monthly Expense', 
                formatter.format(avgAmount),
                Icons.calculate,
                Colors.blue,
              ),
              const Divider(),
              _buildStatItem(
                'Highest Expense Month', 
                '$maxMonthName (${formatter.format(maxAmount)})',
                Icons.arrow_upward,
                Colors.red,
              ),
              const Divider(),
              _buildStatItem(
                'Lowest Expense Month', 
                '$minMonthName (${formatter.format(minAmount)})',
                Icons.arrow_downward,
                Colors.green,
              ),
              const Divider(),
              _buildStatItem(
                'Total Months', 
                '${_monthlyData.length}',
                Icons.calendar_month,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeUtils.getHighlightColor(context, color),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<MapEntry<String, dynamic>> data;
  final double maxValue;
  final Color color;
  
  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    for (int i = 0; i < data.length; i++) {
      final x = i * (size.width / (data.length - 1));
      final y = size.height - (data[i].value as double) / maxValue * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Draw dots at data points
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
