import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/admin/dashboard/model/admin_dashboard_notifier.dart';
import 'package:society_management/admin/dashboard/widget/admin_quick_actions_section.dart';
import 'package:society_management/admin/dashboard/widget/admin_summary_section.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/chat/view/chat_page.dart';
import 'package:society_management/chat/view/society_insights_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/settings/view/common_settings_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/kdv_logo.dart';
import 'package:society_management/widget/welcome_section.dart';

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

  // Future<void> getUserDetail() async {
  //   isLoading.value = true;
  //   final failOrSuccess = await getIt<ICustomerRepository>().customerDetail(
  //     id: widget.customerId,
  //   );
  //   failOrSuccess.fold(
  //     (l) {
  //       isLoading.value = false;
  //       Utility.toast(message: l.formttedMessgeage);
  //     },
  //     (r) {
  //       customer.value = r;
  //       if (r.cars.isNotEmpty) carList.value = r.cars;
  //     },
  //   );
  //   isLoading.value = false;
  // }

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(const ChatPage());
        },
        backgroundColor: AppColors.buttonColor,
        tooltip: 'AI Assistant',
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
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
                      Expanded(
                        child: Column(
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
                      ),
                    ],
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      tooltip: 'More options',
                      onSelected: (value) {
                        switch (value) {
                          case 'insights':
                            context.push(const SocietyInsightsPage());
                            break;
                          case 'settings':
                            context.push(const CommonSettingsPage());
                            break;
                          case 'logout':
                            _logout();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'insights',
                          child: Row(
                            children: [
                              Icon(Icons.insights),
                              SizedBox(width: 12),
                              Text('Society Insights (AI)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings),
                              SizedBox(width: 12),
                              Text('Settings'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 12),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
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
                          const WelcomeSectionView(
                            title: 'Welcome, Admin!',
                            subtitle: 'Manage your society with ease',
                            icon: Icons.admin_panel_settings,
                          ),
                          // const AdminWlcomeSectionView(),
                          const Gap(24),
                          // Summary cards
                          AdminSummarySection(dashboardNotifier: _dashboardNotifier),
                          const Gap(32),
                          // Quick actions
                          const AdminQuickActionsSection(),
                          const Gap(24),
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
