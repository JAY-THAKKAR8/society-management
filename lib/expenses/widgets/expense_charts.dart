import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/theme/theme_utils.dart';

class ExpenseCharts extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final Map<String, dynamic>? statistics;
  final double? totalMaintenance;

  const ExpenseCharts({
    super.key,
    required this.expenses,
    required this.statistics,
    this.totalMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    if (statistics == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildCategoryPieChart(context),
        const SizedBox(height: 24),
        if (totalMaintenance != null && totalMaintenance! > 0) _buildExpenseVsMaintenanceComparison(context),
        const SizedBox(height: 24),
        _buildMonthlyTrendChart(context),
      ],
    );
  }

  Widget _buildCategoryPieChart(BuildContext context) {
    final categoryTotals = statistics!['category_totals'] as Map<String, dynamic>? ?? {};
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

    // Take top 5 categories for better visualization
    final topCategories = sortedCategories.take(5).toList();

    // Calculate total for percentage
    final totalAmount = statistics!['total_amount'] as double? ?? 1.0;

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
          height: 200,
          child: _buildSimplePieChart(context, topCategories, totalAmount),
        ),
      ],
    );
  }

  Widget _buildSimplePieChart(
    BuildContext context,
    List<MapEntry<String, dynamic>> categories,
    double totalAmount,
  ) {
    final isDark = ThemeUtils.isDarkMode(context);

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth * 0.5;
      final centerX = constraints.maxWidth / 2;
      const centerY = 100.0;

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
            size: Size(constraints.maxWidth, 200),
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
            child: _buildLegend(context, categories, totalAmount),
          ),
        ],
      );
    });
  }

  Widget _buildLegend(
    BuildContext context,
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

  Widget _buildExpenseVsMaintenanceComparison(BuildContext context) {
    if (totalMaintenance == null || totalMaintenance! <= 0) {
      return const SizedBox.shrink();
    }

    final totalExpense = statistics!['total_amount'] as double? ?? 0.0;
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    final balance = totalMaintenance! - totalExpense;
    final isPositive = balance >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expenses vs Maintenance Collection',
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
                      context,
                      'Total Expenses',
                      totalExpense,
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                  ),
                  Expanded(
                    child: _buildComparisonItem(
                      context,
                      'Total Collection',
                      totalMaintenance!,
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
                value: totalMaintenance! > 0 ? (totalExpense / totalMaintenance!).clamp(0.0, 1.0) : 0.0,
                backgroundColor: ThemeUtils.isDarkMode(context) ? Colors.grey.withAlpha(50) : Colors.grey.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  totalExpense > totalMaintenance! ? Colors.red : Colors.green,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonItem(
    BuildContext context,
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

  Widget _buildMonthlyTrendChart(BuildContext context) {
    final monthlyTotals = statistics!['monthly_totals'] as Map<String, dynamic>? ?? {};
    if (monthlyTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort months chronologically
    final sortedMonths = monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Take last 6 months for better visualization
    final recentMonths = sortedMonths.length > 6 ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

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
          height: 200,
          child: _buildSimpleBarChart(context, recentMonths),
        ),
      ],
    );
  }

  Widget _buildSimpleBarChart(
    BuildContext context,
    List<MapEntry<String, dynamic>> monthlyData,
  ) {
    // Find the maximum value for scaling
    double maxValue = 0;
    for (final entry in monthlyData) {
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
        color: ThemeUtils.isDarkMode(context) ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = (constraints.maxWidth - 20) / monthlyData.length - 10;

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

              // Bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyData.map((entry) {
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
            ],
          );
        },
      ),
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
    final center = Offset(size.width / 2, 100);
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
