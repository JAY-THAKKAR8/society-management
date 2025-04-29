import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/complaints/view/add_complaint_page.dart';
import 'package:society_management/complaints/view/my_complaints_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/dashboard/line_head_dashboard.dart';
import 'package:society_management/dashboard/widgets/line_member_quick_actions.dart';
import 'package:society_management/dashboard/widgets/line_member_summary_section.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/my_maintenance_status_page.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';

class LineMemberDashboard extends StatefulWidget {
  const LineMemberDashboard({super.key});

  @override
  State<LineMemberDashboard> createState() => _LineMemberDashboardState();
}

class _LineMemberDashboardState extends State<LineMemberDashboard> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  List<UserModel> _lineMembers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
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
    if (_currentUser?.role == 'LINE_HEAD_MEMBER') {
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
                context.pushAndRemoveUntil(const LineHeadDashboard());
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
      appBar: AppBar(
        title: Text(
          "Welcome, ${_currentUser?.name ?? 'Member'}",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        actions: [
          // Show switch to line head view button only for LINE_HEAD_MEMBER users
          if (_currentUser?.role == 'LINE_HEAD_MEMBER')
            IconButton(
              icon: const Icon(Icons.switch_account),
              onPressed: _switchToLineHeadView,
              tooltip: 'Switch to Line Head View',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              context.push(UserInformationPage(user: _currentUser));
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LineMemberSummarySection(
                    lineNumber: _currentUser?.lineNumber,
                  ),
                  const SizedBox(height: 24),
                  LineMemberQuickActions(
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
                ],
              ),
            ),
    );
  }

  Widget _buildLineInfo() {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Line Information",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow("Line", _currentUser?.userLineViewString ?? "Not assigned"),
            _buildInfoRow("Role", _currentUser?.userRoleViewString ?? "Line member"),
            if (_currentUser?.villNumber != null)
              _buildInfoRow("Villa Number", _currentUser?.villNumber ?? "Not assigned"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineMembersList() {
    if (_lineMembers.isEmpty) {
      return Card(
        color: AppColors.lightBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
        ),
      );
    }

    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        color: AppColors.greyText,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._lineMembers.map((member) => _buildMemberItem(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(UserModel member) {
    final bool isLineHead = member.role == 'LINE_HEAD' || member.role == 'LINE_HEAD_MEMBER';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLineHead ? Colors.blue.withOpacity(0.2) : AppColors.buttonColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.name?.isNotEmpty == true ? member.name!.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLineHead ? Colors.blue : AppColors.buttonColor,
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
                        color: isLineHead ? Colors.blue : null,
                      ),
                ),
                if (member.villNumber != null)
                  Text(
                    'Villa: ${member.villNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.greyText,
                        ),
                  ),
              ],
            ),
          ),
          if (isLineHead)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Line Head',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
