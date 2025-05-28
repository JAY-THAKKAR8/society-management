import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/dashboard/widgets/fixed_gradient_summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/my_maintenance_status_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/utility.dart';

class ImprovedLineMemberSummarySection extends StatefulWidget {
  final String? lineNumber;

  const ImprovedLineMemberSummarySection({
    super.key,
    this.lineNumber,
  });

  @override
  State<ImprovedLineMemberSummarySection> createState() => _ImprovedLineMemberSummarySectionState();
}

class _ImprovedLineMemberSummarySectionState extends State<ImprovedLineMemberSummarySection> {
  bool _isLoading = true;
  int _lineMembers = 0;
  int _pendingPayments = 0;
  int _fullyPaidUsers = 0;
  double _collectedAmount = 0.0;
  double _pendingAmount = 0.0;
  int _activeMaintenancePeriods = 0;

  @override
  void initState() {
    super.initState();
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

      // Get user stats using the dashboard stats repository
      final statsRepository = getIt<IDashboardStatsRepository>();
      final result = await statsRepository.getUserStats(widget.lineNumber!);

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
              "My Payment Summary",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0x33C850C0) // 20% opacity of primaryPink
                    : const Color(0x1AEC4899), // 10% opacity of lightAccent
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Member Stats",
                style: TextStyle(
                  color: isDarkMode ? AppColors.primaryPink : AppColors.lightAccent,
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
              title: "My Status",
              value: _isLoading ? "Loading..." : "Active",
              gradientColors: isDarkMode
                  ? [const Color(0xFF3F51B5), const Color(0xFF2196F3)] // Blue gradient
                  : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // Light blue gradient
            ),
            GradientSummaryCard(
              icon: Icons.pending_actions,
              title: "My Pending Payment",
              value: _isLoading ? "Loading..." : (_pendingPayments > 0 ? "Due" : "Clear"),
              gradientColors: isDarkMode
                  ? [const Color(0xFFFF9800), const Color(0xFFFFB300)] // Orange gradient
                  : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Light amber gradient
              onTap: () {
                if (widget.lineNumber != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyMaintenanceStatusPage(),
                    ),
                  );
                }
              },
            ),
            GradientSummaryCard(
              icon: Icons.check_circle,
              title: "My Payment Status",
              value: _isLoading ? "Loading..." : (_fullyPaidUsers > 0 ? "Paid" : "Unpaid"),
              gradientColors: isDarkMode
                  ? [const Color(0xFF43A047), const Color(0xFF26A69A)] // Green gradient
                  : [const Color(0xFF10B981), const Color(0xFF34D399)], // Light green gradient
              onTap: () {
                if (widget.lineNumber != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyMaintenanceStatusPage(),
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
            ),
            GradientSummaryCard(
              icon: Icons.monetization_on,
              title: "My Paid Amount",
              value: _isLoading ? "Loading..." : "₹${_collectedAmount.toStringAsFixed(2)}",
              gradientColors: isDarkMode
                  ? [const Color(0xFF00897B), const Color(0xFF4DB6AC)] // Teal gradient
                  : [const Color(0xFF14B8A6), const Color(0xFF5EEAD4)], // Light teal gradient
            ),
            GradientSummaryCard(
              icon: Icons.money_off,
              title: "My Due Amount",
              value: _isLoading ? "Loading..." : "₹${_pendingAmount.toStringAsFixed(2)}",
              gradientColors: isDarkMode
                  ? [const Color(0xFFE53935), const Color(0xFFFF5252)] // Red gradient
                  : [const Color(0xFFEF4444), const Color(0xFFF87171)], // Light red gradient
              onTap: () {
                if (widget.lineNumber != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyMaintenanceStatusPage(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
