import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/view/add_user_page.dart';
import 'package:society_management/users/widget/user_info_widget.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

/// A high-quality reusable widget for displaying user information in a list
/// Features: Proper AppColors usage, clean design, no refresh functionality
class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onResetPassword;

  const UserListItem({
    super.key,
    required this.user,
    this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? AppColors.darkCard : AppColors.lightContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(isDarkMode),
          width: user.isAdmin || user.isLineHead ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info section
            UserInfoWidget(user: user),

            const SizedBox(height: 12),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Get border color based on user role and theme using AppColors
  Color _getBorderColor(bool isDarkMode) {
    if (user.isAdmin) {
      return AppColors.red.withValues(alpha: isDarkMode ? 0.4 : 0.6);
    } else if (user.isLineHead) {
      return AppColors.lightInfo.withValues(alpha: isDarkMode ? 0.4 : 0.6);
    } else {
      return isDarkMode ? AppColors.white.withValues(alpha: 0.1) : AppColors.lightDivider;
    }
  }

  /// Build action buttons row with proper AppColors styling
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Edit button
        TextButton.icon(
          onPressed: () async {
            await context.push(AddUserPage(userId: user.id));
          },
          icon: const Icon(
            Icons.edit,
            size: 18,
            color: AppColors.lightInfo,
          ),
          label: const Text(
            'Edit',
            style: TextStyle(color: AppColors.lightInfo),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Reset Password button
        TextButton.icon(
          onPressed: onResetPassword,
          icon: const Icon(
            Icons.lock_reset,
            size: 18,
            color: AppColors.lightWarning,
          ),
          label: const Text(
            'Reset Password',
            style: TextStyle(color: AppColors.lightWarning),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
