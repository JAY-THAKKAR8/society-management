import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/line_member_dashboard.dart';
import 'package:society_management/dashboard/widgets/line_head_activity_section.dart';
import 'package:society_management/dashboard/widgets/line_head_quick_actions.dart';
import 'package:society_management/dashboard/widgets/line_head_summary_section.dart';
import 'package:society_management/expenses/view/expense_dashboard_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/line_head_alert_dialog.dart';
import 'package:society_management/settings/view/common_settings_page.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';

class LineHeadDashboard extends StatefulWidget {
  const LineHeadDashboard({super.key});

  @override
  State<LineHeadDashboard> createState() => _LineHeadDashboardState();
}

class _LineHeadDashboardState extends State<LineHeadDashboard> {
  // Keys to force refresh the dashboard widgets
  final GlobalKey<LineHeadSummarySectionState> _summaryKey = GlobalKey<LineHeadSummarySectionState>();
  final GlobalKey<LineHeadActivitySectionState> _activityKey = GlobalKey<LineHeadActivitySectionState>();

  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for pending maintenance after the widget is fully built
    if (_currentUser != null && _currentUser?.lineNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPendingMaintenance();
      });
    }
  }

  Future<void> _checkPendingMaintenance() async {
    try {
      if (_currentUser?.lineNumber == null) return;

      // Get active maintenance periods
      final maintenanceRepository = getIt<IMaintenanceRepository>();
      final periodsResult = await maintenanceRepository.getActiveMaintenancePeriods();

      periodsResult.fold(
        (failure) {
          // Silently fail, we don't want to disrupt the dashboard
          debugPrint('Error checking maintenance periods: ${failure.message}');
        },
        (periods) async {
          if (periods.isEmpty) return;

          // For each active period, check if there are pending payments in this line
          for (final period in periods) {
            if (period.id == null) continue;

            final paymentsResult = await maintenanceRepository.getPaymentsForLine(
              periodId: period.id!,
              lineNumber: _currentUser!.lineNumber!,
            );

            paymentsResult.fold(
              (failure) {
                // Silently fail
                debugPrint('Error checking payments: ${failure.message}');
              },
              (payments) {
                // Count pending payments
                final pendingPayments = payments
                    .where(
                        (payment) => payment.status == PaymentStatus.pending || payment.status == PaymentStatus.overdue)
                    .toList();

                if (pendingPayments.isNotEmpty) {
                  // Calculate total pending amount
                  double pendingAmount = 0;
                  for (final payment in pendingPayments) {
                    if (payment.amount != null) {
                      pendingAmount += (payment.amount! - payment.amountPaid);
                    }
                  }

                  // Show alert dialog
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => LineHeadAlertDialog(
                        period: period,
                        lineNumber: _currentUser!.lineNumber!,
                        pendingCount: pendingPayments.length,
                        pendingAmount: pendingAmount,
                      ),
                    );
                  }

                  // Only show one alert at a time
                  return; // Exit the loop after showing one alert
                }
              },
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Error in _checkPendingMaintenance: $e');
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Verify this is a line head or line head + member
        if (!user.isLineHead) {
          Utility.toast(message: 'Access denied: Not a line head');
          await _logout();
          return;
        }

        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        Utility.toast(message: 'Failed to get user data');
        // If we can't get user data, log out and go to login page
        await _logout();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Utility.toast(message: 'Error: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.pushAndRemoveUntil(const LoginPage());
      }
    } catch (e) {
      Utility.toast(message: 'Error logging out: $e');
    }
  }

  // Switch to member view for LINE_HEAD_MEMBER users
  void _switchToMemberView() {
    if (_currentUser?.role == 'LINE_HEAD_MEMBER') {
      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch to Member View'),
          content: const Text(
              'You are about to switch to your member dashboard where you can view your personal maintenance status and other member-specific features.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to member dashboard
                context.pushAndRemoveUntil(const LineMemberDashboard());
              },
              child: const Text('Switch'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonGradientAppBar(
        title: "Welcome, ${_currentUser?.name ?? 'Line Head'}",
        gradientColors: AppColors.gradientGreenTeal,
        actions: [
          // Show switch to member view button only for LINE_HEAD_MEMBER users
          if (_currentUser?.role == AppConstants.lineHeadAndMember)
            IconButton(
              icon: const Icon(Icons.switch_account),
              onPressed: _switchToMemberView,
              tooltip: 'Switch to Member View',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force refresh all dashboard sections
              _summaryKey.currentState?.refreshStats();
              _activityKey.currentState?.refreshActivities();
            },
            tooltip: 'Refresh dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              context.push(const ExpenseDashboardPage());
            },
            tooltip: 'Expense Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(const CommonSettingsPage());
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              context.push(UserInformationPage(user: _currentUser));
            },
            tooltip: 'Society Information',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LineHeadSummarySection(
                    key: _summaryKey,
                    lineNumber: _currentUser?.lineNumber,
                  ),
                  const SizedBox(height: 24),
                  LineHeadQuickActions(
                    lineNumber: _currentUser?.lineNumber,
                    onActionComplete: () {
                      // Refresh both dashboard sections
                      _summaryKey.currentState?.refreshStats();
                      _activityKey.currentState?.refreshActivities();
                    },
                  ),
                  const SizedBox(height: 24),
                  LineHeadActivitySection(
                    key: _activityKey,
                    lineNumber: _currentUser?.lineNumber,
                  ),
                ],
              ),
            ),
    );
  }
}
