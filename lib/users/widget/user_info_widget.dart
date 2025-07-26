import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/users/model/user_model.dart';

/// A reusable widget for displaying user information
class UserInfoWidget extends StatelessWidget {
  final UserModel user;
  final bool showAvatar;
  final bool showRole;
  final bool showContactInfo;
  final bool showLocationInfo;

  const UserInfoWidget({
    super.key,
    required this.user,
    this.showAvatar = true,
    this.showRole = true,
    this.showContactInfo = true,
    this.showLocationInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar section
        if (showAvatar) ...[
          _buildUserAvatar(),
          const SizedBox(width: 16),
        ],

        // User details section
        Expanded(
          child: _buildUserDetails(context),
        ),

        // Role badge section
        if (showRole) _buildRoleBadge(context),
      ],
    );
  }

  /// Build user avatar with role-based color
  Widget _buildUserAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: user.roleColor.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _getUserInitial(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: user.roleColor,
          ),
        ),
      ),
    );
  }

  /// Build user details column
  Widget _buildUserDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User name
        Text(
          user.name ?? 'Unknown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        // Email
        if (showContactInfo && user.email != null) ...[
          const SizedBox(height: 2),
          Text(
            user.email!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.greyText,
                ),
          ),
        ],

        // Villa number
        if (showLocationInfo && user.villNumber != null) ...[
          const SizedBox(height: 2),
          Text(
            'Villa: ${user.villNumber}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.greyText,
                ),
          ),
        ],

        // Line number
        if (showLocationInfo && user.lineNumber != null) ...[
          const SizedBox(height: 2),
          Text(
            'Line: ${user.userLineViewString}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.greyText,
                ),
          ),
        ],
      ],
    );
  }

  /// Build role badge
  Widget _buildRoleBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: user.roleColor.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.userRoleViewString,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: user.roleColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// Get user initial for avatar
  String _getUserInitial() {
    return user.name?.isNotEmpty == true ? user.name!.substring(0, 1).toUpperCase() : '?';
  }
}
