import 'package:flutter/material.dart';
import 'package:society_management/expenses/view/category_chart_page.dart';
import 'package:society_management/expenses/view/expense_vs_collection_page.dart';
import 'package:society_management/expenses/view/monthly_trend_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class ExpenseChartsPage extends StatelessWidget {
  const ExpenseChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Expense Analytics',
        showDivider: true,
        onBackTap: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Chart Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              context,
              title: 'Category Breakdown',
              description: 'View expenses by category with detailed percentages',
              icon: Icons.pie_chart,
              color: Colors.purple,
              onTap: () => context.push(const CategoryChartPage()),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              context,
              title: 'Expense vs Collection',
              description: 'Compare expenses with maintenance collections',
              icon: Icons.compare_arrows,
              color: Colors.orange,
              onTap: () => context.push(const ExpenseVsCollectionPage()),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              context,
              title: 'Monthly Trends',
              description: 'Track expense patterns over time',
              icon: Icons.trending_up,
              color: Colors.teal,
              onTap: () => context.push(const MonthlyTrendPage()),
            ),
            const SizedBox(height: 24),
            _buildNewFeatureCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ThemeAwareCard(
      useContainerColor: true,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeUtils.getHighlightColor(context, color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewFeatureCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(33, 150, 243, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(33, 150, 243, 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(33, 150, 243, 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Coming Soon: Budget Planning',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Set monthly budgets for different expense categories and track your spending against your budget. Get alerts when you\'re approaching your limits.',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Show a coming soon message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget planning feature coming soon!'),
                    ),
                  );
                },
                child: const Text('Learn More'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
