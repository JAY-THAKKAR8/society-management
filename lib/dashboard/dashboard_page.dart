import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/widgets/quick_actions_section.dart';
import 'package:society_management/dashboard/widgets/recent_activity_section.dart';
import 'package:society_management/dashboard/widgets/summary_section.dart';
import 'package:society_management/expenses/view/add_expense_page.dart';
import 'package:society_management/users/view/add_user_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Keys to force refresh the dashboard widgets
  final GlobalKey<SummarySectionState> _summaryKey = GlobalKey<SummarySectionState>();
  final GlobalKey<RecentActivitySectionState> _activityKey = GlobalKey<RecentActivitySectionState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome, Admin",
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force refresh all dashboard sections
              _summaryKey.currentState?.refreshStats();
              _activityKey.currentState?.refreshActivities();
            },
            tooltip: 'Refresh dashboard',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SummarySection(key: _summaryKey),
            const SizedBox(height: 24),
            QuickActionsSection(
              onAddUser: () async {
                // Navigate to add user page and refresh when returning
                await context.push(const AddUserPage());
                // Refresh both dashboard sections
                _summaryKey.currentState?.refreshStats();
                _activityKey.currentState?.refreshActivities();
              },
              onAddExpense: () async {
                // Navigate to add expense page and refresh when returning
                await context.push(const AddExpensePage());
                // Refresh both dashboard sections
                _summaryKey.currentState?.refreshStats();
                _activityKey.currentState?.refreshActivities();
              },
            ),
            const SizedBox(height: 24),
            RecentActivitySection(key: _activityKey),
          ],
        ),
      ),
    );
  }
}
