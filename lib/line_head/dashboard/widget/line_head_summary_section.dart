import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/dashboard/widgets/summary_card.dart';
import 'package:society_management/line_head/dashboard/model/line_head_dashboard_notifier.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';

class LineHeadSummarySection extends StatelessWidget {
  final LineHeadDashboardNotifier dashboardNotifier;

  const LineHeadSummarySection({
    super.key,
    required this.dashboardNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LineHeadDashboardState>(
      valueListenable: dashboardNotifier,
      builder: (context, state, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Line Summary",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (state.isStatsLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      if (state.currentUser?.lineNumber != null) {
                        dashboardNotifier.loadStats(state.currentUser!.lineNumber!);
                      }
                    },
                    tooltip: 'Refresh stats',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    icon: Icons.group,
                    title: "Line Members",
                    value: state.isStatsLoading ? "Loading..." : "${state.lineMembers}",
                    iconColor: Colors.blue,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: SummaryCard(
                    icon: Icons.pending_actions,
                    title: "Pending Payments",
                    value: state.isStatsLoading ? "Loading..." : "${state.pendingPayments}",
                    iconColor: Colors.orange,
                    onTap: () {
                      if (state.currentUser?.lineNumber != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MaintenancePeriodsPage(),
                          ),
                        );
                      }
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
                    icon: Icons.monetization_on,
                    title: "Pending Amount",
                    value: state.isStatsLoading ? "Loading..." : "₹${state.pendingAmount.toStringAsFixed(2)}",
                    iconColor: Colors.red,
                    onTap: () {
                      if (state.currentUser?.lineNumber != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MaintenancePeriodsPage(),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: SummaryCard(
                    icon: Icons.payments,
                    title: "Collected Amount",
                    value: state.isStatsLoading ? "Loading..." : "₹${state.collectedAmount.toStringAsFixed(2)}",
                    iconColor: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    icon: Icons.check_circle,
                    title: "Fully Paid",
                    value: state.isStatsLoading ? "Loading..." : "${state.fullyPaidUsers}",
                    iconColor: Colors.green,
                    onTap: () {
                      if (state.currentUser?.lineNumber != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MaintenancePeriodsPage(),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: SummaryCard(
                    icon: Icons.calendar_month,
                    title: "Active Periods",
                    value: state.isStatsLoading ? "Loading..." : "${state.activeMaintenancePeriods}",
                    iconColor: Colors.purple,
                    onTap: () {
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
          ],
        );
      },
    );
  }
}
