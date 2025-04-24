import 'package:flutter/material.dart';
import 'package:society_management/dashboard/service/maintenance_stats_service.dart';
import 'package:society_management/dashboard/widgets/quick_action_button.dart';
import 'package:society_management/maintenance/view/line_wise_maintenance_stats_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    this.onAddUser,
    this.onAddExpense,
    this.onBroadcastNotice,
    this.onViewReport,
    this.onManageMaintenance,
  });
  
  final void Function()? onAddUser;
  final void Function()? onAddExpense;
  final void Function()? onBroadcastNotice;
  final void Function()? onViewReport;
  final void Function()? onManageMaintenance;

  Future<void> _viewLineStats(BuildContext context) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading maintenance statistics...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Get the latest active maintenance period
      final maintenanceService = MaintenanceStatsService();
      final result = await maintenanceService.getLatestActivePeriod();

      result.fold(
        (failure) {
          Utility.toast(message: failure.message);
        },
        (period) {
          if (period == null) {
            Utility.toast(message: 'No active maintenance period found');
            return;
          }

          // Navigate to line stats page
          context.push(
            LineWiseMaintenanceStatsPage(
              periodId: period.id!,
              periodName: period.name ?? 'Current Period',
            ),
          );
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error loading maintenance period: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            QuickActionButton(
              icon: Icons.person_add,
              label: "Add User",
              onPressed: onAddUser,
            ),
            QuickActionButton(
              icon: Icons.attach_money,
              label: "Add Expense",
              onPressed: onAddExpense,
            ),
            QuickActionButton(
              icon: Icons.calendar_month,
              label: "Manage Maintenance",
              onPressed: onManageMaintenance,
            ),
            QuickActionButton(
              icon: Icons.analytics,
              label: "Line Statistics",
              onPressed: () => _viewLineStats(context),
            ),
            QuickActionButton(
              icon: Icons.campaign,
              label: "Broadcast Notice",
              onPressed: onBroadcastNotice,
            ),
            QuickActionButton(
              icon: Icons.bar_chart,
              label: "View Report",
              onPressed: onViewReport,
            ),
          ],
        ),
      ],
    );
  }
}
