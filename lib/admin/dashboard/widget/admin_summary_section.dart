import 'package:flutter/material.dart';
import 'package:society_management/admin/dashboard/model/admin_dashboard_notifier.dart';
import 'package:society_management/dashboard/widgets/improved_summary_card.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/users/view/line_users_page.dart';

class AdminSummarySection extends StatelessWidget {
  final AdminDashboardNotifier dashboardNotifier;

  const AdminSummarySection({
    super.key,
    required this.dashboardNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminDashboardState>(
      valueListenable: dashboardNotifier,
      builder: (context, state, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard Overview",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(context, state),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminDashboardState state) {
    print("${state.stats?.totalExpenses.toStringAsFixed(2)}Total expenses");
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Total Members Card
        ImprovedSummaryCard(
          icon: Icons.group,
          title: "Total Members",
          value: state.isLoading
              ? "Loading..."
              : state.stats != null
                  ? "${state.stats!.totalMembers}"
                  : "0",
          startColor: const Color(0xFF4158D0),
          endColor: const Color(0xFFC850C0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LineUsersPage(),
              ),
            );
          },
        ),

        // Maintenance Dues Card
        ImprovedSummaryCard(
          icon: Icons.monetization_on,
          title: "Maintenance Dues",
          value: state.isLoading
              ? "Loading..."
              : state.stats != null
                  ? "₹${state.stats!.maintenancePending.toStringAsFixed(2)}"
                  : "₹0",
          startColor: const Color(0xFFFF416C),
          endColor: const Color(0xFFFF4B2B),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MaintenancePeriodsPage(),
              ),
            );
          },
        ),

        // Total Expenses Card
        ImprovedSummaryCard(
          icon: Icons.inventory,
          title: "Total Expenses",
          value: state.isLoading
              ? "Loading..."
              : state.stats != null
                  ? "₹${state.stats!.totalExpenses.toStringAsFixed(2)}"
                  : "₹0",
          startColor: const Color(0xFF43CEA2),
          endColor: const Color(0xFF185A9D),
        ),

        // Collected Payment Card
        ImprovedSummaryCard(
          icon: Icons.payments,
          title: "Collected Payment",
          value: state.isLoading
              ? "Loading..."
              : state.stats != null
                  ? "₹${state.stats!.maintenanceCollected.toStringAsFixed(2)}"
                  : "₹0",
          startColor: const Color(0xFF56CCF2),
          endColor: const Color(0xFF2F80ED),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MaintenancePeriodsPage(),
              ),
            );
          },
        ),

        // Active Maintenance Card
        ImprovedSummaryCard(
          icon: Icons.calendar_month,
          title: "Active Maintenance",
          value: state.isLoading
              ? "Loading..."
              : state.stats != null
                  ? "${state.stats!.activeMaintenance}"
                  : "0",
          startColor: const Color(0xFF11998E),
          endColor: const Color(0xFF38EF7D),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MaintenancePeriodsPage(),
              ),
            );
          },
        ),

        // Collection Rate Card
        ImprovedSummaryCard(
          icon: Icons.pie_chart,
          title: "Collection Rate",
          value: state.isLoading ? "Loading..." : state.calculateCollectionRate(),
          startColor: const Color(0xFFFF8008),
          endColor: const Color(0xFFFFC837),
        ),
      ],
    );
  }
}
