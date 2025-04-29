import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/widgets/summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/my_maintenance_status_page.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/utility.dart';

class LineMemberSummarySection extends StatefulWidget {
  final String? lineNumber;

  const LineMemberSummarySection({
    super.key,
    this.lineNumber,
  });

  @override
  State<LineMemberSummarySection> createState() => _LineMemberSummarySectionState();
}

class _LineMemberSummarySectionState extends State<LineMemberSummarySection> {
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
          maintenanceRepository.getActiveMaintenancePeriods().then(
            (periodsResult) {
              periodsResult.fold(
                (failure) {
                  Utility.toast(message: failure.message);
                  setState(() {
                    _isLoading = false;
                  });
                },
                (periods) {
                  _activeMaintenancePeriods = periods.length;

                  // For each period, get payments for this line
                  if (periods.isEmpty) {
                    setState(() {
                      _isLoading = false;
                    });
                    return;
                  }

                  // Get payments for the most recent period
                  final latestPeriod = periods.first;
                  maintenanceRepository
                      .getPaymentsForPeriod(
                    periodId: latestPeriod.id!,
                  )
                      .then(
                    (paymentsResult) {
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
                    },
                  );
                },
              );
            },
          );
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
        Text(
          "Line Summary",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.group,
                title: "Line Members",
                value: _isLoading ? "Loading..." : "$_lineMembers",
                iconColor: Colors.blue,
              ),
            ),
            const Gap(16),
            Expanded(
              child: SummaryCard(
                icon: Icons.pending_actions,
                title: "Pending Payments",
                value: _isLoading ? "Loading..." : "$_pendingPayments",
                iconColor: Colors.orange,
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
                value: _isLoading ? "Loading..." : "$_fullyPaidUsers",
                iconColor: Colors.green,
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
            ),
            const Gap(16),
            Expanded(
              child: SummaryCard(
                icon: Icons.calendar_month,
                title: "Active Periods",
                value: _isLoading ? "Loading..." : "$_activeMaintenancePeriods",
                iconColor: Colors.purple,
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
                title: "Collected Amount",
                value: _isLoading ? "Loading..." : "₹${_collectedAmount.toStringAsFixed(2)}",
                iconColor: Colors.green.shade600,
              ),
            ),
            const Gap(16),
            Expanded(
              child: SummaryCard(
                icon: Icons.money_off,
                title: "Pending Amount",
                value: _isLoading ? "Loading..." : "₹${_pendingAmount.toStringAsFixed(2)}",
                iconColor: Colors.red,
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
            ),
          ],
        ),
      ],
    );
  }
}
