import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/widgets/quick_actions_section_new.dart';
import 'package:society_management/dashboard/widgets/recent_activity_section.dart';
import 'package:society_management/dashboard/widgets/summary_section.dart';
import 'package:society_management/expenses/view/add_expense_page.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/view/user_management_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Keys to force refresh the dashboard widgets
  final GlobalKey<SummarySectionState> _summaryKey = GlobalKey<SummarySectionState>();
  final GlobalKey<RecentActivitySectionState> _activityKey = GlobalKey<RecentActivitySectionState>();

  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome, ${_currentUser?.name ?? 'Admin'}",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        actions: [
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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
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
                  SummarySection(key: _summaryKey),
                  const SizedBox(height: 24),
                  QuickActionsSection(
                    onAddUser: () async {
                      // Navigate to user management page and refresh when returning
                      await context.push(const UserManagementPage());
                      // Refresh both dashboard sections
                      _summaryKey.currentState?.refreshStats();
                      _activityKey.currentState?.refreshActivities();
                    },
                    onAddExpense: () async {
                      // Navigate to add expense page and refresh when returning
                      await context.push(const AddExpensePage());
                      // Refresh both dashboard sections
                      _summaryKey.currentState?.refreshStats();
                      _activityKey.currentState?.refreshActivities();
                    },
                    onManageMaintenance: () async {
                      // Navigate to maintenance periods page and refresh when returning
                      await context.push(const MaintenancePeriodsPage());
                      // Refresh both dashboard sections
                      _summaryKey.currentState?.refreshStats();
                      _activityKey.currentState?.refreshActivities();
                    },
                  ),
                  const SizedBox(height: 24),
                  RecentActivitySection(key: _activityKey),
                ],
              ),
            ),
    );
  }
}
