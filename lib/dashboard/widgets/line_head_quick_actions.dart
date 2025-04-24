import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/maintenance/view/line_member_maintenance_page.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/users/view/line_head_users_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class LineHeadQuickActions extends StatelessWidget {
  final String? lineNumber;
  final VoidCallback? onActionComplete;

  const LineHeadQuickActions({
    super.key,
    this.lineNumber,
    this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: "View Line Members",
                icon: Icons.group,
                onTap: () async {
                  await context.push(const LineHeadUsersPage());
                  onActionComplete?.call();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                title: "Collect Maintenance",
                icon: Icons.payments,
                onTap: () async {
                  await context.push(LineMemberMaintenancePage(lineNumber: lineNumber));
                  onActionComplete?.call();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: "View Maintenance Periods",
                icon: Icons.calendar_month,
                onTap: () async {
                  await context.push(const MaintenancePeriodsPage());
                  onActionComplete?.call();
                },
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()), // Empty space for balance
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppColors.buttonColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
