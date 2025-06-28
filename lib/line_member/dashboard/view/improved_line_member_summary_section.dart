import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/dashboard/widgets/fixed_gradient_summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/my_maintenance_status_page.dart';
import 'package:society_management/meetings/model/meeting_model.dart';
import 'package:society_management/meetings/repository/i_meeting_repository.dart';
import 'package:society_management/meetings/view/meeting_dashboard_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/utility.dart';

// Data model for line member stats
class LineMemberStats {
  final bool isLoading;
  final int lineMembers;
  final int pendingPayments;
  final int fullyPaidUsers;
  final double collectedAmount;
  final double pendingAmount;
  final int upcomingMeetings;
  final String? errorMessage;

  const LineMemberStats({
    this.isLoading = true,
    this.lineMembers = 0,
    this.pendingPayments = 0,
    this.fullyPaidUsers = 0,
    this.collectedAmount = 0.0,
    this.pendingAmount = 0.0,
    this.upcomingMeetings = 0,
    this.errorMessage,
  });

  LineMemberStats copyWith({
    bool? isLoading,
    int? lineMembers,
    int? pendingPayments,
    int? fullyPaidUsers,
    double? collectedAmount,
    double? pendingAmount,
    int? upcomingMeetings,
    String? errorMessage,
  }) {
    return LineMemberStats(
      isLoading: isLoading ?? this.isLoading,
      lineMembers: lineMembers ?? this.lineMembers,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      fullyPaidUsers: fullyPaidUsers ?? this.fullyPaidUsers,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      upcomingMeetings: upcomingMeetings ?? this.upcomingMeetings,
      errorMessage: errorMessage,
    );
  }
}

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
  late final ValueNotifier<LineMemberStats> _statsNotifier;
  final IDashboardStatsRepository _statsRepository = getIt<IDashboardStatsRepository>();
  final IMeetingRepository _meetingRepository = getIt<IMeetingRepository>();

  @override
  void initState() {
    super.initState();
    _statsNotifier = ValueNotifier(const LineMemberStats());
    _loadStats();
  }

  @override
  void dispose() {
    _statsNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (widget.lineNumber == null) {
      _statsNotifier.value = _statsNotifier.value.copyWith(
        isLoading: false,
        errorMessage: 'Line number not available',
      );
      return;
    }

    try {
      _statsNotifier.value = _statsNotifier.value.copyWith(isLoading: true, errorMessage: null);

      // Load both stats and meetings concurrently for better performance
      final statsResult = await _statsRepository.getUserStats(widget.lineNumber!);

      // Handle meeting loading with proper error handling
      List<MeetingModel> upcomingMeetings = [];
      try {
        // All users see all meetings - no line filtering needed
        upcomingMeetings = await _meetingRepository.getUpcomingMeetings();
      } catch (e) {
        // Continue with empty meetings list instead of failing completely
        // Log error for debugging but don't crash the dashboard
      }

      statsResult.fold(
        (failure) {
          _statsNotifier.value = _statsNotifier.value.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          Utility.toast(message: 'Error loading stats: ${failure.message}');
        },
        (stats) {
          // Calculate pending payments as total members minus fully paid users
          final pendingPayments = (stats.totalMembers - stats.fullyPaidUsers).clamp(0, stats.totalMembers);

          _statsNotifier.value = _statsNotifier.value.copyWith(
            isLoading: false,
            lineMembers: stats.totalMembers,
            pendingAmount: stats.maintenancePending,
            collectedAmount: stats.maintenanceCollected,
            fullyPaidUsers: stats.fullyPaidUsers,
            upcomingMeetings: upcomingMeetings.length,
            pendingPayments: pendingPayments,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      _statsNotifier.value = _statsNotifier.value.copyWith(
        isLoading: false,
        errorMessage: 'Error loading data: $e',
      );
      Utility.toast(message: 'Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return ValueListenableBuilder<LineMemberStats>(
      valueListenable: _statsNotifier,
      builder: (context, stats, child) {
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
            if (stats.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stats.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
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
                  value: stats.isLoading ? "Loading..." : "Active",
                  gradientColors: isDarkMode
                      ? [const Color(0xFF3F51B5), const Color(0xFF2196F3)] // Blue gradient
                      : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // Light blue gradient
                ),
                GradientSummaryCard(
                  icon: Icons.pending_actions,
                  title: "My Pending Payment",
                  value: stats.isLoading ? "Loading..." : (stats.pendingPayments > 0 ? "Due" : "Clear"),
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
                  value: stats.isLoading ? "Loading..." : (stats.fullyPaidUsers > 0 ? "Paid" : "Unpaid"),
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
                  icon: Icons.groups,
                  title: "Upcoming Meetings",
                  value: stats.isLoading ? "Loading..." : "${stats.upcomingMeetings}",
                  gradientColors: isDarkMode
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)] // Red-Yellow gradient
                      : [const Color(0xFFEF4444), const Color(0xFFFBBF24)], // Light red to yellow
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MeetingDashboardPage(),
                      ),
                    );
                  },
                ),
                GradientSummaryCard(
                  icon: Icons.monetization_on,
                  title: "My Paid Amount",
                  value: stats.isLoading ? "Loading..." : "₹${stats.collectedAmount.toStringAsFixed(2)}",
                  gradientColors: isDarkMode
                      ? [const Color(0xFF00897B), const Color(0xFF4DB6AC)] // Teal gradient
                      : [const Color(0xFF14B8A6), const Color(0xFF5EEAD4)], // Light teal gradient
                ),
                GradientSummaryCard(
                  icon: Icons.money_off,
                  title: "My Due Amount",
                  value: stats.isLoading ? "Loading..." : "₹${stats.pendingAmount.toStringAsFixed(2)}",
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
      },
    );
  }
}
