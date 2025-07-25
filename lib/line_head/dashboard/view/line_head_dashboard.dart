import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/chat/view/chat_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/expenses/view/expense_dashboard_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/line_head/dashboard/view/improved_line_head_quick_actions.dart';
import 'package:society_management/line_head/dashboard/view/improved_line_head_summary_section.dart';
import 'package:society_management/line_head/dashboard/widget/line_head_alert_dialog.dart';
import 'package:society_management/line_member/dashboard/view/line_member_dashboard.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/notifications/service/notification_service.dart';
import 'package:society_management/settings/view/common_settings_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/screenshot_utility.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/kdv_logo.dart';
import 'package:society_management/widget/welcome_section.dart';

class LineHeadDashboard extends StatefulWidget {
  const LineHeadDashboard({super.key});

  @override
  State<LineHeadDashboard> createState() => _LineHeadDashboardState();
}

class _LineHeadDashboardState extends State<LineHeadDashboard> with SingleTickerProviderStateMixin {
  // Keys to force refresh the dashboard widgets - using unique keys to prevent duplication
  final GlobalKey<ImprovedLineHeadSummarySectionState> _summaryKey = GlobalKey<ImprovedLineHeadSummarySectionState>();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    log('________________________________');
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _getCurrentUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for pending maintenance after the widget is fully built
    if (_currentUser != null && _currentUser?.lineNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
            '🚨 Checking pending maintenance for Line Head: ${_currentUser?.name}, Line: ${_currentUser?.lineNumber}');
        _checkPendingMaintenance();
      });
    }
  }

  Future<void> _checkPendingMaintenance() async {
    try {
      debugPrint('🔍 _checkPendingMaintenance started');
      if (_currentUser?.lineNumber == null) {
        debugPrint('❌ No current user or line number found');
        return;
      }

      debugPrint('✅ Line Head: ${_currentUser?.name}, Line: ${_currentUser?.lineNumber}');

      // Get active maintenance periods
      final maintenanceRepository = getIt<IMaintenanceRepository>();
      debugPrint('📋 Getting active maintenance periods...');
      final periodsResult = await maintenanceRepository.getActiveMaintenancePeriods();

      periodsResult.fold(
        (failure) {
          // Silently fail, we don't want to disrupt the dashboard
          debugPrint('❌ Error checking maintenance periods: ${failure.message}');
        },
        (periods) async {
          debugPrint('📋 Found ${periods.length} active periods');
          if (periods.isEmpty) {
            debugPrint('❌ No active periods found');
            return;
          }

          // Sort periods by due date (most recent first)
          periods.sort((a, b) {
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return DateTime.parse(b.dueDate!).compareTo(DateTime.parse(a.dueDate!));
          });

          // Calculate total amounts across ALL periods
          MaintenancePeriodModel? latestPeriod;
          int totalPendingCount = 0;
          double totalPendingAmount = 0;
          double totalCollectedAmount = 0;
          Set<String> uniquePendingUsers = {};

          // For each active period, accumulate totals
          for (final period in periods) {
            if (period.id == null) continue;

            // Keep track of the latest period for display
            latestPeriod ??= period;

            debugPrint('🔍 Checking payments for period: ${period.name}, Line: ${_currentUser!.lineNumber}');
            final paymentsResult = await maintenanceRepository.getPaymentsForLine(
              periodId: period.id!,
              lineNumber: _currentUser!.lineNumber!,
            );

            paymentsResult.fold(
              (failure) {
                // Silently fail
                debugPrint('❌ Error checking payments: ${failure.message}');
              },
              (payments) {
                debugPrint('💰 Found ${payments.length} payments for this period');

                // Calculate amounts for this period and add to totals
                for (final payment in payments) {
                  if (payment.amount != null) {
                    // Add to total collected amount
                    totalCollectedAmount += payment.amountPaid;

                    // Calculate remaining amount
                    final remainingAmount = payment.amount! - payment.amountPaid;
                    if (remainingAmount > 0) {
                      totalPendingAmount += remainingAmount;
                      // Track unique users with pending payments
                      if (payment.userId != null) {
                        uniquePendingUsers.add(payment.userId!);
                      }
                    }
                  }
                }
              },
            );
          }

          // Set final counts - use latest period for display but show total amounts
          totalPendingCount = uniquePendingUsers.length;

          // Show alert dialog if there are pending payments or collected amounts
          debugPrint('🚨 Final check: latestPeriod = ${latestPeriod?.name}, mounted = $mounted');
          debugPrint('📊 Total Pending count: $totalPendingCount, Total Pending amount: ₹$totalPendingAmount');
          debugPrint('💰 Total Collected amount: ₹$totalCollectedAmount');

          if ((totalPendingAmount > 0 || totalCollectedAmount > 0) && latestPeriod != null && mounted) {
            debugPrint('✅ Showing Line Head Alert Dialog with TOTAL amounts');

            // Send collection alert notification if there are pending amounts
            if (totalPendingAmount > 0) {
              try {
                await NotificationService.sendLineHeadCollectionAlert(
                  lineHeadUserId: _currentUser!.id!,
                  lineNumber: _currentUser!.lineNumber!,
                  pendingCount: totalPendingCount,
                  pendingAmount: totalPendingAmount,
                  periodName: latestPeriod.name ?? 'Current Period',
                );
              } catch (e) {
                debugPrint('Failed to send line head collection alert: $e');
              }
            }

            // Add small delay to ensure UI is fully loaded
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // Show dialog with total amounts across all periods
                showDialog(
                  context: context,
                  barrierDismissible: false, // User must interact with the dialog
                  builder: (context) => LineHeadAlertDialog(
                    period: latestPeriod!, // Use latest period for display
                    lineNumber: _currentUser!.lineNumber!,
                    pendingCount: totalPendingCount, // Total pending users
                    pendingAmount: totalPendingAmount, // Total pending amount
                    collectedAmount: totalCollectedAmount, // Total collected amount
                  ),
                );
              }
            });
          } else {
            debugPrint(
                '❌ Alert dialog NOT shown - latestPeriod: ${latestPeriod?.name}, totalPending: ₹$totalPendingAmount, mounted: $mounted');
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

        // Start animations
        _animationController.forward();

        // Check for pending maintenance after user is loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint(
              '🚨 User loaded, checking pending maintenance for Line Head: ${user.name}, Line: ${user.lineNumber}');
          _checkPendingMaintenance();
        });

        // Test alert removed - real alert is working!
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
    if (_currentUser?.role == AppConstants.lineHeadAndMember) {
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
                context.pushAndRemoveUntil(const ImprovedLineMemberDashboard());
              },
              child: const Text('Switch'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _refreshDashboard() async {
    _summaryKey.currentState?.refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(const ChatPage());
        },
        backgroundColor: AppColors.primaryBlue,
        tooltip: 'AI Assistant',
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: RepaintBoundary(
        key: ScreenshotUtility.screenshotKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [AppColors.darkBackground, const Color(0xFF121428)] // Dark background with blue tint
                  : AppColors.gradientGreenTeal,
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      slivers: [
                        // App Bar
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          floating: true,
                          elevation: 0,
                          title: const Row(
                            children: [
                              KDVLogo(
                                size: 40,
                                primaryColor: AppColors.primaryGreen,
                                secondaryColor: Colors.white,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KDV Management',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Line Head Dashboard',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xB3FFFFFF), // 70% opacity of white
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            // Show switch to member view button only for LINE_HEAD_MEMBER users
                            if (_currentUser?.role == AppConstants.lineHeadAndMember)
                              IconButton(
                                icon: const Icon(Icons.switch_account, color: Colors.white),
                                onPressed: _switchToMemberView,
                                tooltip: 'Switch to Member View',
                              ),
                            // More menu with additional options
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              tooltip: 'More options',
                              onSelected: (value) {
                                switch (value) {
                                  case 'expense':
                                    context.push(const ExpenseDashboardPage());
                                    break;
                                  case 'screenshot':
                                    ScreenshotUtility.takeAndShareScreenshot(context);
                                    break;
                                  case 'settings':
                                    context.push(const CommonSettingsPage());
                                    break;
                                  case 'info':
                                    context.push(UserInformationPage(user: _currentUser));
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'expense',
                                  child: Row(
                                    children: [
                                      Icon(Icons.bar_chart),
                                      SizedBox(width: 12),
                                      Text('Expense Dashboard'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'screenshot',
                                  child: Row(
                                    children: [
                                      Icon(Icons.camera_alt),
                                      SizedBox(width: 12),
                                      Text('Take Screenshot'),
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
                                  value: 'info',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline),
                                      SizedBox(width: 12),
                                      Text('Society Information'),
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

                                  WelcomeSectionView(
                                    title: 'Welcome, ${_currentUser?.name ?? 'Line Head'}!',
                                    subtitle: 'Manage your line with ease',
                                    icon: Icons.supervisor_account,
                                  ),
                                  const SizedBox(height: 24),

                                  // Summary cards
                                  ImprovedLineHeadSummarySection(
                                    key: _summaryKey,
                                    lineNumber: _currentUser?.lineNumber,
                                  ),
                                  const SizedBox(height: 32),

                                  // Quick actions
                                  ImprovedLineHeadQuickActions(
                                    lineNumber: _currentUser?.lineNumber,
                                    onActionComplete: () {
                                      // Refresh both dashboard sections
                                      _summaryKey.currentState?.refreshStats();
                                    },
                                  ),
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
      ),
    );
  }
}
