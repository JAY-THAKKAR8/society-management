import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/dashboard/widgets/fixed_gradient_summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/utility.dart';

class ImprovedLineHeadSummarySection extends StatefulWidget {
  final String? lineNumber;

  const ImprovedLineHeadSummarySection({
    super.key,
    this.lineNumber,
  });

  @override
  State<ImprovedLineHeadSummarySection> createState() => ImprovedLineHeadSummarySectionState();
}

class ImprovedLineHeadSummarySectionState extends State<ImprovedLineHeadSummarySection> {
  bool _isLoading = true;
  int _lineMembers = 0;
  int _pendingPayments = 0;
  int _fullyPaidUsers = 0;
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
            // Directly use the values from the stats collection
            _lineMembers = stats.totalMembers;
            _pendingAmount = stats.maintenancePending;
            _collectedAmount = stats.maintenanceCollected;
            _activeMaintenancePeriods = stats.activeMaintenance;
            _fullyPaidUsers = stats.fullyPaidUsers;

            // Calculate pending payments as total members minus fully paid users
            _pendingPayments = _lineMembers - _fullyPaidUsers;

            // Ensure we don't have negative values
            if (_pendingPayments < 0) {
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
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Line Summary",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0x3311998E) // 20% opacity of primaryGreen
                    : const Color(0x1A10B981), // 10% opacity of lightGreen
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Line Head Stats",
                style: TextStyle(
                  color: isDarkMode ? AppColors.primaryGreen : AppColors.lightGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            GradientSummaryCard(
              icon: Icons.group,
              title: "Line Members",
              value: _isLoading ? "Loading..." : "$_lineMembers",
              gradientColors: isDarkMode
                  ? [const Color(0xFF00796B), const Color(0xFF009688)] // Teal gradient
                  : [const Color(0xFF0D9488), const Color(0xFF14B8A6)], // Light teal gradient
            ),
            GradientSummaryCard(
              icon: Icons.pending_actions,
              title: "Pending Payments",
              value: _isLoading ? "Loading..." : "$_pendingPayments",
              gradientColors: isDarkMode
                  ? [const Color(0xFFFF9800), const Color(0xFFFFB300)] // Orange gradient
                  : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Light amber gradient
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
            GradientSummaryCard(
              icon: Icons.monetization_on,
              title: "Pending Amount",
              value: _isLoading ? "Loading..." : "₹${_pendingAmount.toStringAsFixed(2)}",
              gradientColors: isDarkMode
                  ? [const Color(0xFFE53935), const Color(0xFFFF5252)] // Red gradient
                  : [const Color(0xFFEF4444), const Color(0xFFF87171)], // Light red gradient
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
            GradientSummaryCard(
              icon: Icons.payments,
              title: "Collected Amount",
              value: _isLoading ? "Loading..." : "₹${_collectedAmount.toStringAsFixed(2)}",
              gradientColors: isDarkMode
                  ? [const Color(0xFF43A047), const Color(0xFF26A69A)] // Green gradient
                  : [const Color(0xFF10B981), const Color(0xFF34D399)], // Light green gradient
            ),
            GradientSummaryCard(
              icon: Icons.check_circle,
              title: "Fully Paid",
              value: _isLoading ? "Loading..." : "$_fullyPaidUsers",
              gradientColors: isDarkMode
                  ? [const Color(0xFF1976D2), const Color(0xFF42A5F5)] // Blue gradient
                  : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // Light blue gradient
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
            GradientSummaryCard(
              icon: Icons.calendar_month,
              title: "Active Periods",
              value: _isLoading ? "Loading..." : "$_activeMaintenancePeriods",
              gradientColors: isDarkMode
                  ? [const Color(0xFF7C4DFF), const Color(0xFFE040FB)] // Purple gradient
                  : [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // Light purple gradient
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MaintenancePeriodsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
