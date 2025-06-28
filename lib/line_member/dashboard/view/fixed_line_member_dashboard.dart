import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/chat/view/chat_page.dart';
import 'package:society_management/complaints/view/add_complaint_page.dart';
import 'package:society_management/complaints/view/my_complaints_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/line_head/dashboard/view/fixed_line_head_dashboard.dart';
import 'package:society_management/line_member/dashboard/view/improved_line_member_quick_actions.dart';
import 'package:society_management/line_member/dashboard/view/improved_line_member_summary_section.dart';
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

// Data model for dashboard state
class LineMemberDashboardState {
  final UserModel? currentUser;
  final List<UserModel> lineMembers;
  final bool isLoading;
  final String? errorMessage;

  const LineMemberDashboardState({
    this.currentUser,
    this.lineMembers = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  LineMemberDashboardState copyWith({
    UserModel? currentUser,
    List<UserModel>? lineMembers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LineMemberDashboardState(
      currentUser: currentUser ?? this.currentUser,
      lineMembers: lineMembers ?? this.lineMembers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Improved Line Member Dashboard with ValueNotifier for better performance
/// Features:
/// - No setState usage - uses ValueNotifier to prevent unnecessary rebuilds
/// - Comprehensive error handling and loading states
/// - Role-based access control
/// - Smooth animations and transitions
class ImprovedLineMemberDashboard extends StatefulWidget {
  const ImprovedLineMemberDashboard({super.key});

  @override
  State<ImprovedLineMemberDashboard> createState() => _ImprovedLineMemberDashboardState();
}

class _ImprovedLineMemberDashboardState extends State<ImprovedLineMemberDashboard> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late final ValueNotifier<LineMemberDashboardState> _dashboardNotifier;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize dashboard state
    _dashboardNotifier = ValueNotifier(const LineMemberDashboardState());

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
    _dashboardNotifier.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Verify this is a line member or line head + member
        if (!user.isLineMember) {
          _dashboardNotifier.value = _dashboardNotifier.value.copyWith(
            isLoading: false,
            errorMessage: 'Access denied: Not a line member',
          );
          Utility.toast(message: 'Access denied: Not a line member');
          await _logout();
          return;
        }

        _dashboardNotifier.value = _dashboardNotifier.value.copyWith(
          currentUser: user,
          isLoading: false,
          errorMessage: null,
        );

        // Start animations
        _animationController.forward();

        // Fetch line members after getting current user
        if (user.lineNumber != null) {
          _fetchLineMembers(user.lineNumber!);
        }
      } else {
        _dashboardNotifier.value = _dashboardNotifier.value.copyWith(
          isLoading: false,
          errorMessage: 'Failed to get user data',
        );
        Utility.toast(message: 'Failed to get user data');
        await _logout();
      }
    } catch (e) {
      _dashboardNotifier.value = _dashboardNotifier.value.copyWith(
        isLoading: false,
        errorMessage: 'Error loading user data: $e',
      );
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
          _dashboardNotifier.value = _dashboardNotifier.value.copyWith(
            errorMessage: 'Error fetching line members: ${failure.message}',
          );
          Utility.toast(message: failure.message);
        },
        (users) {
          final currentUser = _dashboardNotifier.value.currentUser;
          final filteredUsers =
              users.where((user) => user.lineNumber == lineNumber && user.id != currentUser?.id).toList();

          _dashboardNotifier.value = _dashboardNotifier.value.copyWith(
            lineMembers: filteredUsers,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      _dashboardNotifier.value = _dashboardNotifier.value.copyWith(
        errorMessage: 'Error fetching line members: $e',
      );
      Utility.toast(message: 'Error fetching line members: $e');
    }
  }

  void _switchToLineHeadView() {
    final currentUser = _dashboardNotifier.value.currentUser;
    if (currentUser?.role == AppConstants.lineHeadAndMember) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch to Line Head View'),
          content: const Text('Do you want to switch to the Line Head dashboard?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
    final currentUser = _dashboardNotifier.value.currentUser;
    if (currentUser?.lineNumber != null) {
      _fetchLineMembers(currentUser!.lineNumber!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return ValueListenableBuilder<LineMemberDashboardState>(
      valueListenable: _dashboardNotifier,
      builder: (context, state, child) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(const ChatPage()),
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
                  colors:
                      isDarkMode ? [AppColors.darkBackground, const Color(0xFF121428)] : AppColors.gradientPurplePink,
                ),
              ),
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.errorMessage != null
                          ? _buildErrorState(state.errorMessage!)
                          : _buildDashboardContent(state),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _getCurrentUser,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(LineMemberDashboardState state) {
    return CustomScrollView(
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
                primaryColor: AppColors.primaryPurple,
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
                    'Member Dashboard',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xB3FFFFFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Show switch button only for LINE_HEAD_MEMBER users
            if (state.currentUser?.role == AppConstants.lineHeadAndMember)
              IconButton(
                icon: const Icon(Icons.switch_account, color: Colors.white),
                onPressed: _switchToLineHeadView,
                tooltip: 'Switch to Line Head View',
              ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => context.push(const CommonSettingsPage()),
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
                  _buildWelcomeSection(state.currentUser),
                  const SizedBox(height: 24),

                  // Summary cards
                  ImprovedLineMemberSummarySection(
                    lineNumber: state.currentUser?.lineNumber,
                  ),
                  const SizedBox(height: 32),

                  // Quick actions
                  ImprovedLineMemberQuickActions(
                    onAddComplaint: () => context.push(const AddComplaintPage()),
                    onViewComplaints: () => context.push(const MyComplaintsPage()),
                    onViewMaintenanceStatus: () => context.push(const MyMaintenanceStatusPage()),
                  ),
                  const SizedBox(height: 24),

                  // Line info
                  _buildLineInfo(state.currentUser),
                  const SizedBox(height: 24),

                  // Line members list
                  _buildLineMembersList(state.lineMembers),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(UserModel? currentUser) {
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
                  'Welcome, ${currentUser?.name ?? 'Member'}!',
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
            decoration: const BoxDecoration(
              color: Color(0x4DFFFFFF),
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

  Widget _buildLineInfo(UserModel? currentUser) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return CommonGradientCard(
      gradientColors: isDarkMode ? [const Color(0xB36A11CB), const Color(0xB3C850C0)] : AppColors.gradientLightPurple,
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
          _buildInfoRow("Line", currentUser?.userLineViewString ?? "Not assigned"),
          _buildInfoRow("Role", currentUser?.userRoleViewString ?? "Line member"),
          if (currentUser?.villNumber != null) _buildInfoRow("Villa Number", currentUser?.villNumber ?? "Not assigned"),
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

  Widget _buildLineMembersList(List<UserModel> lineMembers) {
    if (lineMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeUtils.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
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
            color: Color(0x0D000000),
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
                "${lineMembers.length} members",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextColor(context, secondary: true),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lineMembers.map((member) => _buildMemberItem(member)),
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
                      ? const Color(0x3311998E)
                      : const Color(0x1A11998E)
                  : isDarkMode
                      ? const Color(0x336A11CB)
                      : const Color(0x1A6A11CB),
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
                color: isDarkMode ? const Color(0x3311998E) : const Color(0x1A11998E),
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
