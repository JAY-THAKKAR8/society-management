import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/dashboard/model/dashboard_notifier.dart';
import 'package:society_management/dashboard/widgets/summary_card.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/users/view/line_users_page.dart';

class SummarySection extends StatefulWidget {
  final DashboardNotifier dashboardNotifier;

  const SummarySection({
    super.key,
    required this.dashboardNotifier,
  });

  @override
  SummarySectionState createState() => SummarySectionState();
}

class SummarySectionState extends State<SummarySection> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app is resumed
      refreshStats();
    }
  }

  // Public method to refresh stats from outside
  void refreshStats() {
    widget.dashboardNotifier.refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardState>(
      valueListenable: widget.dashboardNotifier,
      builder: (context, state, _) {
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dashboard Summary",
                  style: theme.textTheme.titleLarge,
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: refreshStats,
                    tooltip: 'Refresh dashboard stats',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    icon: Icons.group,
                    title: "Total Members",
                    value: state.isLoading
                        ? "Loading..."
                        : state.stats != null
                            ? "${state.stats!.totalMembers}"
                            : "0",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LineUsersPage(),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: SummaryCard(
                    icon: Icons.monetization_on,
                    title: "Maintenance Dues",
                    value: state.isLoading
                        ? "Loading..."
                        : state.stats != null
                            ? "₹${state.stats!.maintenancePending.toStringAsFixed(2)}"
                            : "₹0",
                    onTap: () {
                      // Navigate to maintenance page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MaintenancePeriodsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    icon: Icons.inventory,
                    title: "Total Expenses",
                    value: state.isLoading
                        ? "Loading..."
                        : state.stats != null
                            ? "₹${state.stats!.totalExpenses.toStringAsFixed(2)}"
                            : "₹0",
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: SummaryCard(
                    icon: Icons.calendar_month,
                    title: "Active Maintenance",
                    value: state.isLoading
                        ? "Loading..."
                        : state.stats != null
                            ? "${state.stats!.activeMaintenance}"
                            : "0",
                    onTap: () {
                      // Navigate to maintenance page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MaintenancePeriodsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Error: ${state.errorMessage}",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }
}
