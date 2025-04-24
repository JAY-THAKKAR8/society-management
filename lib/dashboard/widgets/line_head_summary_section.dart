import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/dashboard/widgets/summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/utility/utility.dart';

class LineHeadSummarySection extends StatefulWidget {
  final String? lineNumber;

  const LineHeadSummarySection({
    super.key,
    this.lineNumber,
  });

  @override
  State<LineHeadSummarySection> createState() => LineHeadSummarySectionState();
}

class LineHeadSummarySectionState extends State<LineHeadSummarySection> {
  bool _isLoading = true;
  int _lineMembers = 0;
  int _pendingPayments = 0;
  double _pendingAmount = 0.0;
  double _collectedAmount = 0.0;
  int _activeMaintenancePeriods = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Public method to refresh stats from outside
  void refreshStats() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (widget.lineNumber == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Get line stats using the dashboard stats repository
      final statsRepository = getIt<IDashboardStatsRepository>();
      final result = await statsRepository.getLineStats(widget.lineNumber!);

      result.fold(
        (failure) {
          Utility.toast(message: failure.message);
          setState(() {
            _isLoading = false;
          });
        },
        (stats) {
          setState(() {
            _lineMembers = stats.totalMembers;
            _pendingAmount = stats.maintenancePending;
            _collectedAmount = stats.maintenanceCollected;
            _activeMaintenancePeriods = stats.activeMaintenance;

            // Calculate pending payments count (approximate)
            if (stats.maintenancePending > 0 && _lineMembers > 0) {
              // Estimate based on average amount per member
              final averageAmount = stats.maintenancePending / _lineMembers;
              if (averageAmount > 0) {
                _pendingPayments = _lineMembers;
              } else {
                _pendingPayments = 0;
              }
            } else {
              _pendingPayments = 0;
            }

            _isLoading = false;
          });
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error loading stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStats,
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
                value: _isLoading ? "Loading..." : "$_lineMembers",
              ),
            ),
            const Gap(16),
            Expanded(
              child: SummaryCard(
                icon: Icons.pending_actions,
                title: "Pending Payments",
                value: _isLoading ? "Loading..." : "$_pendingPayments",
                onTap: () {
                  if (widget.lineNumber != null) {
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
                value: _isLoading ? "Loading..." : "₹${_pendingAmount.toStringAsFixed(2)}",
                onTap: () {
                  if (widget.lineNumber != null) {
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
                value: _isLoading ? "Loading..." : "₹${_collectedAmount.toStringAsFixed(2)}",
              ),
            ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.calendar_month,
                title: "Active Periods",
                value: _isLoading ? "Loading..." : "$_activeMaintenancePeriods",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MaintenancePeriodsPage(),
                    ),
                  );
                },
              ),
            ),
            const Expanded(child: SizedBox()), // Empty space for balance
          ],
        ),
      ],
    );
  }
}
