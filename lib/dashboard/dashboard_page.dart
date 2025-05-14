import 'package:flutter/material.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/model/dashboard_notifier.dart';
import 'package:society_management/dashboard/widgets/quick_actions_section_new.dart';
import 'package:society_management/dashboard/widgets/recent_activity_section.dart';
import 'package:society_management/dashboard/widgets/summary_section.dart';
import 'package:society_management/expenses/view/expense_dashboard_page.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/settings/view/settings_page.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/users/view/user_management_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Key for activity section
  final GlobalKey<RecentActivitySectionState> _activityKey = GlobalKey<RecentActivitySectionState>();

  // Dashboard notifier
  final DashboardNotifier _dashboardNotifier = DashboardNotifier();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _dashboardNotifier.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardState>(
      valueListenable: _dashboardNotifier,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Welcome, ${state.currentUser?.name ?? 'Admin'}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Force refresh all dashboard sections
                  _dashboardNotifier.refreshStats();
                  _activityKey.currentState?.refreshActivities();
                },
                tooltip: 'Refresh dashboard',
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  context.push(UserInformationPage(user: state.currentUser));
                },
                tooltip: 'Society Information',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  context.push(const SettingsPage());
                },
                tooltip: 'Settings',
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
                      SummarySection(dashboardNotifier: _dashboardNotifier),
                      const SizedBox(height: 24),
                      QuickActionsSection(
                        onAddUser: () async {
                          // Navigate to user management page and refresh when returning
                          await context.push(const UserManagementPage());
                          // Refresh both dashboard sections
                          _dashboardNotifier.refreshStats();
                          _activityKey.currentState?.refreshActivities();
                        },
                        onAddExpense: () async {
                          // Navigate to expense dashboard page and refresh when returning
                          await context.push(const ExpenseDashboardPage());
                          // Refresh both dashboard sections
                          _dashboardNotifier.refreshStats();
                          _activityKey.currentState?.refreshActivities();
                        },
                        onManageMaintenance: () async {
                          // Navigate to maintenance periods page and refresh when returning
                          await context.push(const MaintenancePeriodsPage());
                          // Refresh both dashboard sections
                          _dashboardNotifier.refreshStats();
                          _activityKey.currentState?.refreshActivities();
                        },
                      ),
                      const SizedBox(height: 24),
                      RecentActivitySection(key: _activityKey),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
