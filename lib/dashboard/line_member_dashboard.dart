import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/complaints/view/add_complaint_page.dart';
import 'package:society_management/complaints/view/my_complaints_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/widgets/line_member_quick_actions.dart';
import 'package:society_management/dashboard/widgets/line_member_summary_section.dart';
import 'package:society_management/maintenance/view/my_maintenance_status_page.dart';
import 'package:society_management/users/model/user_model.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Verify this is a line member
        if (user.role != AppConstants.lineMember) {
          Utility.toast(message: 'Access denied: Not a line member');
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
}
