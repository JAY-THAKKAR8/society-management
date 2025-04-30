import 'package:flutter/material.dart';
import 'package:society_management/complaints/view/basic_complaints_page.dart';
import 'package:society_management/dashboard/widgets/improved_quick_action_button.dart';
import 'package:society_management/expenses/view/add_expense_page.dart';
import 'package:society_management/maintenance/view/improved_active_maintenance_stats_page.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/users/view/user_management_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class ImprovedQuickActionsSection extends StatelessWidget {
  const ImprovedQuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions ",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionsGrid(context),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Manage Users
        ImprovedQuickActionButton(
          icon: Icons.people,
          label: "Manage Users",
          startColor: const Color(0xFF6A11CB),
          endColor: const Color(0xFF2575FC),
          onPressed: () {
            context.push(const UserManagementPage());
          },
        ),

        // Manage Maintenance
        ImprovedQuickActionButton(
          icon: Icons.calendar_today,
          label: "Manage Maintenance",
          startColor: const Color(0xFFFF416C),
          endColor: const Color(0xFFFF4B2B),
          onPressed: () {
            context.push(const MaintenancePeriodsPage());
          },
        ),

        // Maintenance Stats
        ImprovedQuickActionButton(
          icon: Icons.bar_chart,
          label: "Maintenance Stats",
          startColor: const Color(0xFF00B4DB),
          endColor: const Color(0xFF0083B0),
          onPressed: () {
            context.push(const ImprovedActiveMaintenanceStatsPage());
          },
        ),

        // Manage Expenses
        ImprovedQuickActionButton(
          icon: Icons.account_balance_wallet,
          label: "Manage Expenses",
          startColor: const Color(0xFF11998E),
          endColor: const Color(0xFF38EF7D),
          onPressed: () {
            context.push(const AddExpensePage());
          },
        ),

        // Manage Complaints
        ImprovedQuickActionButton(
          icon: Icons.comment,
          label: "Manage Complaints",
          startColor: const Color(0xFFFF8008),
          endColor: const Color(0xFFFFC837),
          onPressed: () {
            context.push(const BasicComplaintsPage());
          },
        ),

        // Society Information
        ImprovedQuickActionButton(
          icon: Icons.info,
          label: "Society Information",
          startColor: const Color(0xFF4158D0),
          endColor: const Color(0xFFC850C0),
          onPressed: () {
            context.push(const UserInformationPage());
          },
        ),
      ],
    );
  }
}
