import 'package:flutter/material.dart';
import 'package:society_management/admin/dashboard/model/admin_dashboard_notifier.dart';
import 'package:society_management/admin/dashboard/widget/admin_quick_actions_section.dart';
import 'package:society_management/admin/dashboard/widget/admin_summary_section.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/kdv_logo.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AdminDashboardNotifier _dashboardNotifier = AdminDashboardNotifier();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _dashboardNotifier.refreshStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dashboardNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    await _dashboardNotifier.refreshStats();
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withBlue(40),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  floating: true,
                  elevation: 0,
                  title: Row(
                    children: [
                      const KDVLogo(
                        size: 40,
                        primaryColor: AppColors.buttonColor,
                        secondaryColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KDV Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        // Show society info
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                ),

                // Dashboard Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome message
                          _buildWelcomeSection(),
                          const SizedBox(height: 24),

                          // Summary cards
                          AdminSummarySection(dashboardNotifier: _dashboardNotifier),
                          const SizedBox(height: 32),

                          // Quick actions
                          const AdminQuickActionsSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC850C0).withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your society with ease',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authService = AuthService();
      await authService.signOut();
      if (mounted) {
        // Navigate to the login page
        context.pushAndRemoveUntil(const LoginPage());
      }
    } catch (e) {
      Utility.toast(message: 'Error logging out: $e');
    }
  }
}
