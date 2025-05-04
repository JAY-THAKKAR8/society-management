import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class CategoryChartPage extends StatefulWidget {
  const CategoryChartPage({super.key});

  @override
  State<CategoryChartPage> createState() => _CategoryChartPageState();
}

class _CategoryChartPageState extends State<CategoryChartPage> {
  final _repository = getIt<IExpenseRepository>();
  bool _isLoading = true;
  Map<String, dynamic>? _statistics;
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

          setState(() {
            _statistics = stats;
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

    for (final expense in expenses) {
      final amount = expense.totalAmount ?? 0;
      totalAmount += amount;

      // Category totals
      final categoryName = expense.categoryName ?? 'Uncategorized';
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + amount;
    }

    return {
      'total_amount': totalAmount,
      'expense_count': expenses.length,
      'category_totals': categoryTotals,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Category Breakdown',
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
          _buildCategoryPieChart(),
          const SizedBox(height: 24),
          _buildCategoryTable(),
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

  Widget _buildCategoryPieChart() {
    if (_statistics == null) {
      return const SizedBox.shrink();
    }

    final categoryTotals = _statistics!['category_totals'] as Map<String, dynamic>? ?? {};
    if (categoryTotals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No expense data available for the selected period'),
        ),
      );
    }

    // Sort categories by amount (highest first)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));
    
    // Calculate total for percentage
    final totalAmount = _statistics!['total_amount'] as double? ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense by Category',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _buildSimplePieChart(sortedCategories, totalAmount),
        ),
      ],
    );
  }

  Widget _buildSimplePieChart(
    List<MapEntry<String, dynamic>> categories,
    double totalAmount,
  ) {
    final isDark = ThemeUtils.isDarkMode(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.5;
        final centerX = constraints.maxWidth / 2;
        final centerY = 150.0;
        
        // Draw pie chart manually
        return Stack(
          children: [
            // Center circle with total
            Positioned(
              left: centerX - size * 0.3,
              top: centerY - size * 0.3,
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        NumberFormat.compactCurrency(
                          symbol: '₹',
                          decimalDigits: 0,
                          locale: 'en_IN',
                        ).format(totalAmount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Pie segments
            CustomPaint(
              size: Size(constraints.maxWidth, 300),
              painter: SimplePieChartPainter(
                categories: categories,
                totalAmount: totalAmount,
                isDarkMode: isDark,
              ),
            ),
            
            // Legend
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildLegend(categories, totalAmount),
            ),
          ],
        );
      }
    );
  }
  
  Widget _buildLegend(
    List<MapEntry<String, dynamic>> categories,
    double totalAmount,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: categories.map((entry) {
        final categoryName = entry.key;
        final amount = entry.value as double;
        final percentage = (amount / totalAmount) * 100;
        final color = _getCategoryColor(categoryName);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ThemeUtils.getHighlightColor(context, color),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$categoryName (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryTable() {
    if (_statistics == null) {
      return const SizedBox.shrink();
    }

    final categoryTotals = _statistics!['category_totals'] as Map<String, dynamic>? ?? {};
    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    // Sort categories by amount (highest first)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));

    final totalAmount = _statistics!['total_amount'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Details',
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
                        'Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
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
              ...sortedCategories.map((entry) {
                final categoryName = entry.key;
                final amount = entry.value as double;
                final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0;
                final color = _getCategoryColor(categoryName);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              formatter.format(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        formatter.format(totalAmount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: Text(
                        '100%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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

  Color _getCategoryColor(String categoryName) {
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
      case 'other':
        return Colors.grey;
      case 'uncategorized':
        return Colors.grey;
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
}

class SimplePieChartPainter extends CustomPainter {
  final List<MapEntry<String, dynamic>> categories;
  final double totalAmount;
  final bool isDarkMode;
  
  SimplePieChartPainter({
    required this.categories,
    required this.totalAmount,
    required this.isDarkMode,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 150);
    final radius = size.width * 0.25;
    
    double startAngle = -90 * (3.14159 / 180); // Start from top (in radians)
    
    for (final entry in categories) {
      final categoryName = entry.key;
      final amount = entry.value as double;
      final sweepAngle = (amount / totalAmount) * 2 * 3.14159;
      
      final paint = Paint()
        ..color = _getCategoryColor(categoryName)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
  
  Color _getCategoryColor(String categoryName) {
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
      case 'other':
        return Colors.grey;
      case 'uncategorized':
        return Colors.grey;
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
}
