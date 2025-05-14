import 'package:flutter/material.dart';
import 'package:society_management/dashboard/widgets/improved_quick_action_button.dart';
import 'package:society_management/expenses/view/expense_dashboard_page.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/users/view/user_management_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class AdminQuickActionsSection extends StatelessWidget {
  const AdminQuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Add User
            ImprovedQuickActionButton(
              label: "Add User",
              icon: Icons.person_add,
              startColor: const Color(0xFF4158D0),
              endColor: const Color(0xFFC850C0),
              onPressed: () {
                context.push(const UserManagementPage());
              },
            ),

            // Add Expense
            ImprovedQuickActionButton(
              label: "Add Expense",
              icon: Icons.receipt_long,
              startColor: const Color(0xFFFF416C),
              endColor: const Color(0xFFFF4B2B),
              onPressed: () {
                context.push(const ExpenseDashboardPage());
              },
            ),

            // Manage Maintenance
            ImprovedQuickActionButton(
              label: "Maintenance",
              icon: Icons.calendar_today,
              startColor: const Color(0xFF43CEA2),
              endColor: const Color(0xFF185A9D),
              onPressed: () {
                context.push(const MaintenancePeriodsPage());
              },
            ),

            // View Reports
            ImprovedQuickActionButton(
              label: "Reports",
              icon: Icons.bar_chart,
              startColor: const Color(0xFF56CCF2),
              endColor: const Color(0xFF2F80ED),
              onPressed: () {
                context.push(const ExpenseDashboardPage());
              },
            ),
          ],
        ),
      ],
    );
  }
}
