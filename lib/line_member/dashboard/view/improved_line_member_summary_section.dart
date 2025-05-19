import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/widgets/fixed_gradient_summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/my_maintenance_status_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
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
      // Get users in this line
      final userRepository = getIt<IUserRepository>();
      final usersResult = await userRepository.getAllUsers();

      usersResult.fold(
        (failure) {
          Utility.toast(message: failure.message);
          setState(() {
            _isLoading = false;
          });
        },
        (users) {
          // Count members in this line (excluding admins)
          final lineUsers = users
              .where((user) =>
                  user.lineNumber == widget.lineNumber &&
                  user.role != 'admin' &&
                  user.role != 'ADMIN' &&
                  user.role != AppConstants.admins)
              .toList();
          _lineMembers = lineUsers.length;

          // Get active maintenance periods
          final maintenanceRepository = getIt<IMaintenanceRepository>();
          maintenanceRepository.getActiveMaintenancePeriods().then((periodsResult) {
            periodsResult.fold(
              (failure) {
                Utility.toast(message: failure.message);
                setState(() {
                  _isLoading = false;
                });
              },
              (periods) {
                _activeMaintenancePeriods = periods.length;

                // If there are active periods, get payment details
                if (periods.isNotEmpty && periods.first.id != null) {
                  maintenanceRepository
                      .getPaymentsForLine(
                    periodId: periods.first.id!,
                    lineNumber: widget.lineNumber!,
                  )
                      .then((paymentsResult) {
                    paymentsResult.fold(
                      (failure) {
                        Utility.toast(message: failure.message);
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      (payments) {
                        // Filter payments for this line (excluding admins)
                        final linePayments = payments
                            .where(
                              (payment) =>
                                  payment.userLineNumber == widget.lineNumber &&
                                  payment.userId != 'admin' &&
                                  payment.userName?.toLowerCase() != 'admin',
                            )
                            .toList();

                        // Count pending and fully paid users
                        _pendingPayments = 0;
                        _fullyPaidUsers = 0;
                        _collectedAmount = 0.0;
                        _pendingAmount = 0.0;

                        for (final payment in linePayments) {
                          final amount = payment.amount ?? 0.0;
                          final amountPaid = payment.amountPaid;

                          // Add to collected amount
                          _collectedAmount += amountPaid;

                          // Check if fully paid or pending
                          if (amountPaid >= amount && amount > 0) {
                            _fullyPaidUsers++;
                          } else if (amount > 0) {
                            _pendingPayments++;
                            _pendingAmount += (amount - amountPaid);
                          }
                        }

                        setState(() {
                          _isLoading = false;
                        });
                      },
                    );
                  });
                } else {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            );
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
              title: "Line Members",
              value: _isLoading ? "Loading..." : "$_lineMembers",
              gradientColors: isDarkMode
                  ? [const Color(0xFF3F51B5), const Color(0xFF2196F3)] // Blue gradient
                  : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // Light blue gradient
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
                      builder: (context) => const MyMaintenanceStatusPage(),
                    ),
                  );
                }
              },
            ),
            GradientSummaryCard(
              icon: Icons.check_circle,
              title: "Fully Paid",
              value: _isLoading ? "Loading..." : "$_fullyPaidUsers",
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
              title: "Collected Amount",
              value: _isLoading ? "Loading..." : "₹${_collectedAmount.toStringAsFixed(2)}",
              gradientColors: isDarkMode
                  ? [const Color(0xFF00897B), const Color(0xFF4DB6AC)] // Teal gradient
                  : [const Color(0xFF14B8A6), const Color(0xFF5EEAD4)], // Light teal gradient
            ),
            GradientSummaryCard(
              icon: Icons.money_off,
              title: "Pending Amount",
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
