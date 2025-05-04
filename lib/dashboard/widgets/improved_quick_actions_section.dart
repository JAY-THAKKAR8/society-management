import 'package:flutter/material.dart';
import 'package:society_management/complaints/view/basic_complaints_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/widgets/improved_quick_action_button.dart';
import 'package:society_management/expenses/view/expense_dashboard_page.dart';
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
          startColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientPurpleBlue[0]
              : AppColors.gradientLightPrimary[0],
          endColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientPurpleBlue[1]
              : AppColors.gradientLightPrimary[1],
          onPressed: () {
            context.push(const UserManagementPage());
          },
        ),

        // Manage Maintenance
        ImprovedQuickActionButton(
          icon: Icons.calendar_today,
          label: "Manage Maintenance",
          startColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientRedPink[0]
              : AppColors.gradientLightRed[0],
          endColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientRedPink[1]
              : AppColors.gradientLightRed[1],
          onPressed: () {
            context.push(const MaintenancePeriodsPage());
          },
        ),

        // Maintenance Stats
        ImprovedQuickActionButton(
          icon: Icons.bar_chart,
          label: "Maintenance Stats",
          startColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientBlueAqua[0]
              : AppColors.gradientLightBlue[0],
          endColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientBlueAqua[1]
              : AppColors.gradientLightBlue[1],
          onPressed: () {
            context.push(const ImprovedActiveMaintenanceStatsPage());
          },
        ),

        // Manage Expenses
        ImprovedQuickActionButton(
          icon: Icons.account_balance_wallet,
          label: "Manage Expenses",
          startColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientGreenTeal[0]
              : AppColors.gradientLightGreen[0],
          endColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientGreenTeal[1]
              : AppColors.gradientLightGreen[1],
          onPressed: () {
            context.push(const ExpenseDashboardPage());
          },
        ),

        // Manage Complaints
        ImprovedQuickActionButton(
          icon: Icons.comment,
          label: "Manage Complaints",
          startColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientOrangeYellow[0]
              : AppColors.gradientLightOrange[0],
          endColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientOrangeYellow[1]
              : AppColors.gradientLightOrange[1],
          onPressed: () {
            context.push(const BasicComplaintsPage());
          },
        ),

        // Society Information
        ImprovedQuickActionButton(
          icon: Icons.info,
          label: "Society Information",
          startColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientPurplePink[0]
              : AppColors.gradientLightPurple[0],
          endColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.gradientPurplePink[1]
              : AppColors.gradientLightPurple[1],
          onPressed: () {
            context.push(const UserInformationPage());
          },
        ),
      ],
    );
  }
}
