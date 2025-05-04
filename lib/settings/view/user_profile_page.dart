import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/role_themed_card.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;

  const UserProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'My Profile',
        showDivider: true,
        onBackTap: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildPersonalInfo(),
            const SizedBox(height: 24),
            _buildRoleInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isDarkMode = ThemeUtils.isDarkMode(context);
    
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: _getRoleColor().withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 60,
              color: _getRoleColor(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.name ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.user.userRoleViewString,
              style: TextStyle(
                color: _getRoleColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        RoleThemedCard(
          userRole: widget.user.role,
          child: Column(
            children: [
              _buildInfoItem(
                icon: Icons.email,
                title: 'Email',
                value: widget.user.email ?? 'Not provided',
                color: AppColors.primaryBlue,
              ),
              const Divider(),
              _buildInfoItem(
                icon: Icons.phone,
                title: 'Mobile Number',
                value: widget.user.mobileNumber ?? 'Not provided',
                color: AppColors.primaryGreen,
              ),
              if (widget.user.villNumber != null) ...[
                const Divider(),
                _buildInfoItem(
                  icon: Icons.home,
                  title: 'Villa Number',
                  value: widget.user.villNumber!,
                  color: AppColors.primaryOrange,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Role Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        RoleThemedCard(
          userRole: widget.user.role,
          child: Column(
            children: [
              _buildInfoItem(
                icon: Icons.badge,
                title: 'Role',
                value: widget.user.userRoleViewString,
                color: _getRoleColor(),
              ),
              const Divider(),
              _buildInfoItem(
                icon: Icons.location_on,
                title: 'Line',
                value: widget.user.userLineViewString,
                color: AppColors.primaryPurple,
              ),
              const Divider(),
              _buildInfoItem(
                icon: Icons.calendar_today,
                title: 'Member Since',
                value: _formatDate(widget.user.createdAt),
                color: AppColors.primaryTeal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDarkMode = ThemeUtils.isDarkMode(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor() {
    switch (widget.user.role) {
      case 'ADMIN':
        return AppColors.primaryBlue;
      case 'LINE_HEAD':
        return AppColors.primaryGreen;
      case 'LINE_MEMBER':
        return AppColors.primaryPurple;
      case 'LINE_HEAD_MEMBER':
        return AppColors.primaryOrange;
      default:
        return AppColors.primaryTeal;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      Utility.toast(message: 'Error formatting date: $e');
      return 'Unknown';
    }
  }
}
