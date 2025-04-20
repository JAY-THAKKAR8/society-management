import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/widgets/quick_actions_section.dart';
import 'package:society_management/dashboard/widgets/recent_activity_section.dart';
import 'package:society_management/dashboard/widgets/summary_section.dart';
import 'package:society_management/expenses/view/add_expense_page.dart';
import 'package:society_management/users/view/add_user_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SummarySection(),
            const SizedBox(height: 24),
            QuickActionsSection(
              onAddUser: () {
                context.push(const AddUserPage());
              },
              onAddExpense: () {
                context.push(const AddExpensePage());
              },
            ),
            const SizedBox(height: 24),
            const RecentActivitySection(),
          ],
        ),
      ),
    );
  }
}
