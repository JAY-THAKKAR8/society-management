import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/complaints/view/add_complaint_page.dart';
import 'package:society_management/complaints/view/my_complaints_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/view/improved_line_head_dashboard.dart';
import 'package:society_management/dashboard/widgets/improved_line_member_quick_actions.dart';
import 'package:society_management/dashboard/widgets/line_member_summary_section.dart';
import 'package:society_management/expenses/view/expense_dashboard_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/my_maintenance_status_page.dart';
import 'package:society_management/settings/view/common_settings_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/screenshot_utility.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_gradient_card.dart';
import 'package:society_management/widget/kdv_logo.dart';

class ImprovedLineMemberDashboard extends StatefulWidget {
  const ImprovedLineMemberDashboard({super.key});

  @override
  State<ImprovedLineMemberDashboard> createState() => _ImprovedLineMemberDashboardState();
}

class _ImprovedLineMemberDashboardState extends State<ImprovedLineMemberDashboard> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  List<UserModel> _lineMembers = [];

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

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

  Future<void> _getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Verify this is a line member or line head + member
        if (!user.isLineMember) {
          Utility.toast(message: 'Access denied: Not a line member');
          await _logout();
          return;
        }

        setState(() {
          _currentUser = user;
          _isLoading = false;
        });

        // Start animations
        _animationController.forward();

        // Fetch line members after getting current user
        if (user.lineNumber != null) {
          _fetchLineMembers(user.lineNumber!);
        }
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

  Future<void> _fetchLineMembers(String lineNumber) async {
    try {
      final userRepository = getIt<IUserRepository>();
      final result = await userRepository.getAllUsers();

      result.fold(
        (failure) {
          Utility.toast(message: failure.message);
        },
        (users) {
          // Filter users by line number
          final filteredUsers =
              users.where((user) => user.lineNumber == lineNumber && user.id != _currentUser?.id).toList();

          setState(() {
            _lineMembers = filteredUsers;
          });
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error fetching line members: $e');
    }
  }

  // Switch to line head view for LINE_HEAD_MEMBER users
  void _switchToLineHeadView() {
    if (_currentUser?.role == AppConstants.lineHeadAndMember) {
      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch to Line Head View'),
          content: const Text(
              'You are about to switch to your line head dashboard where you can manage maintenance collections and other line head responsibilities.'),
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
                // Navigate to line head dashboard
                context.pushAndRemoveUntil(const ImprovedLineHeadDashboard());
              },
              child: const Text('Switch'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _refreshDashboard() async {
    if (_currentUser?.lineNumber != null) {
      _fetchLineMembers(_currentUser!.lineNumber!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      body: RepaintBoundary(
        key: ScreenshotUtility.screenshotKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [AppColors.darkBackground, AppColors.darkBackground.withBlue(40)]
                  : AppColors.gradientPurplePink,
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
                          title: Row(
                            children: [
                              const KDVLogo(
                                size: 40,
                                primaryColor: AppColors.primaryPurple,
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
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Member Dashboard',
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
                            // Show switch to line head view button only for LINE_HEAD_MEMBER users
                            if (_currentUser?.role == AppConstants.lineHeadAndMember)
                              IconButton(
                                icon: const Icon(Icons.switch_account, color: Colors.white),
                                onPressed: _switchToLineHeadView,
                                tooltip: 'Switch to Line Head View',
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
                                  _buildWelcomeSection(),
                                  const SizedBox(height: 24),

                                  // Summary cards
                                  LineMemberSummarySection(
                                    lineNumber: _currentUser?.lineNumber,
                                  ),
                                  const SizedBox(height: 32),

                                  // Quick actions
                                  ImprovedLineMemberQuickActions(
                                    onAddComplaint: () {
                                      context.push(const AddComplaintPage());
                                    },
                                    onViewComplaints: () {
                                      context.push(const MyComplaintsPage());
                                    },
                                    onViewMaintenanceStatus: () {
                                      context.push(const MyMaintenanceStatusPage());
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Line member specific content
                                  _buildLineInfo(),
                                  const SizedBox(height: 24),

                                  // Line members list
                                  _buildLineMembersList(),
                                  const SizedBox(height: 100), // Extra space at bottom
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

  Widget _buildWelcomeSection() {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return CommonGradientCard(
      gradientColors: isDarkMode ? AppColors.gradientPurplePink : AppColors.gradientLightPurple,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${_currentUser?.name ?? 'Member'}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay updated with your society',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 0.25,
                    color: Colors.white,
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
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineInfo() {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return CommonGradientCard(
      gradientColors: isDarkMode
          ? [const Color(0xB36A11CB), const Color(0xB3C850C0)] // 70% opacity of primaryPurple and primaryPink
          : AppColors.gradientLightPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Line Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow("Line", _currentUser?.userLineViewString ?? "Not assigned"),
          _buildInfoRow("Role", _currentUser?.userRoleViewString ?? "Line member"),
          if (_currentUser?.villNumber != null)
            _buildInfoRow("Villa Number", _currentUser?.villNumber ?? "Not assigned"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineMembersList() {
    if (_lineMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeUtils.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000), // 5% opacity of black
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Line Members",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "No other members in your line",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // 5% opacity of black
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Line Members",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                "${_lineMembers.length} members",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextColor(context, secondary: true),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._lineMembers.map((member) => _buildMemberItem(member)),
        ],
      ),
    );
  }

  Widget _buildMemberItem(UserModel member) {
    final bool isLineHead = member.isLineHead;
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLineHead
                  ? isDarkMode
                      ? const Color(0x3311998E) // 20% opacity of primaryGreen
                      : const Color(0x1A11998E) // 10% opacity of primaryGreen
                  : isDarkMode
                      ? const Color(0x336A11CB) // 20% opacity of primaryPurple
                      : const Color(0x1A6A11CB), // 10% opacity of primaryPurple
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.name?.isNotEmpty == true ? member.name!.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLineHead ? AppColors.primaryGreen : AppColors.primaryPurple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLineHead ? AppColors.primaryGreen : null,
                      ),
                ),
                if (member.villNumber != null)
                  Text(
                    'Villa: ${member.villNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextColor(context, secondary: true),
                        ),
                  ),
              ],
            ),
          ),
          if (isLineHead)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0x3311998E) // 20% opacity of primaryGreen
                    : const Color(0x1A11998E), // 10% opacity of primaryGreen
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Line Head',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
