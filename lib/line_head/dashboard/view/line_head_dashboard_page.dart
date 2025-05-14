import 'package:flutter/material.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/line_member_dashboard.dart';
import 'package:society_management/dashboard/widgets/line_head_activity_section.dart';
import 'package:society_management/dashboard/widgets/line_head_quick_actions.dart';
import 'package:society_management/expenses/view/expense_dashboard_page.dart';
import 'package:society_management/line_head/dashboard/model/line_head_dashboard_notifier.dart';
import 'package:society_management/line_head/dashboard/widget/line_head_summary_section.dart';
import 'package:society_management/maintenance/view/line_head_alert_dialog.dart';
import 'package:society_management/settings/view/common_settings_page.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';

class LineHeadDashboardPage extends StatefulWidget {
  const LineHeadDashboardPage({super.key});

  @override
  State<LineHeadDashboardPage> createState() => _LineHeadDashboardPageState();
}

class _LineHeadDashboardPageState extends State<LineHeadDashboardPage> {
  // Key for activity section
  final GlobalKey<LineHeadActivitySectionState> _activityKey = GlobalKey<LineHeadActivitySectionState>();

  // Dashboard notifier
  final LineHeadDashboardNotifier _dashboardNotifier = LineHeadDashboardNotifier();

  @override
  void initState() {
    super.initState();
    // Check for pending maintenance after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingMaintenanceAlerts();
    });
  }

  @override
  void dispose() {
    _dashboardNotifier.dispose();
    super.dispose();
  }

  void _checkPendingMaintenanceAlerts() {
    // Listen for changes to the dashboard state
    _dashboardNotifier.addListener(() {
      final state = _dashboardNotifier.value;

      // Show alerts for pending maintenance periods
      if (state.pendingPeriods.isNotEmpty && state.currentUser?.lineNumber != null) {
        // Only show one alert at a time
        final period = state.pendingPeriods.first;
        final periodId = period.id;

        if (periodId != null && state.pendingPaymentsByPeriod.containsKey(periodId)) {
          final pendingPayments = state.pendingPaymentsByPeriod[periodId]!;

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
                lineNumber: state.currentUser!.lineNumber!,
                pendingCount: pendingPayments.length,
                pendingAmount: pendingAmount,
              ),
            );
          }
        }
      }
    });
  }

  Future<void> _logout() async {
    try {
      await _dashboardNotifier.logout();
      if (mounted) {
        context.pushAndRemoveUntil(const LoginPage());
      }
    } catch (e) {
      // Error is already handled in the notifier
    }
  }

  // Switch to member view for LINE_HEAD_MEMBER users
  void _switchToMemberView() {
    final currentUser = _dashboardNotifier.value.currentUser;
    if (currentUser?.role == AppConstants.lineHeadAndMember) {
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
    return ValueListenableBuilder<LineHeadDashboardState>(
      valueListenable: _dashboardNotifier,
      builder: (context, state, _) {
        return Scaffold(
          appBar: CommonGradientAppBar(
            title: "Welcome, ${state.currentUser?.name ?? 'Line Head'}",
            gradientColors: AppColors.gradientGreenTeal,
            actions: [
              // Show switch to member view button only for LINE_HEAD_MEMBER users
              if (state.currentUser?.role == AppConstants.lineHeadAndMember)
                IconButton(
                  icon: const Icon(Icons.switch_account),
                  onPressed: _switchToMemberView,
                  tooltip: 'Switch to Member View',
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Force refresh all dashboard sections
                  _dashboardNotifier.refreshAll();
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
                  context.push(UserInformationPage(user: state.currentUser));
                },
                tooltip: 'Society Information',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: state.isUserLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LineHeadSummarySection(
                        dashboardNotifier: _dashboardNotifier,
                      ),
                      const SizedBox(height: 24),
                      LineHeadQuickActions(
                        lineNumber: state.currentUser?.lineNumber,
                        onActionComplete: () {
                          // Refresh both dashboard sections
                          _dashboardNotifier.refreshAll();
                          _activityKey.currentState?.refreshActivities();
                        },
                      ),
                      const SizedBox(height: 24),
                      LineHeadActivitySection(
                        key: _activityKey,
                        lineNumber: state.currentUser?.lineNumber,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
