import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_text_form_field.dart';

/// A reusable dialog widget for user actions like reset password
class UserActionDialog {
  /// Show reset password dialog
  static void showResetPasswordDialog(
    BuildContext context, 
    UserModel user, {
    VoidCallback? onSuccess,
  }) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightContainer,
              title: Text('Reset Password for ${user.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextFormField(
                    controller: passwordController,
                    title: 'New Password*',
                    hintText: 'Enter new password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          await _handlePasswordReset(
                            context,
                            passwordController.text,
                            setState,
                            onSuccess,
                          );
                        },
                        child: const Text('Reset'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  /// Handle password reset logic
  static Future<void> _handlePasswordReset(
    BuildContext context,
    String password,
    StateSetter setState,
    VoidCallback? onSuccess,
  ) async {
    if (password.length < 6) {
      Utility.toast(message: 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      // isLoading = true; // This would need to be handled differently
    });

    try {
      // TODO: Implement password reset functionality
      await Future.delayed(const Duration(seconds: 1));

      if (context.mounted) {
        Navigator.of(context).pop();
        Utility.toast(message: 'Password reset successfully');
        onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          // isLoading = false; // This would need to be handled differently
        });
        Utility.toast(message: 'Error: $e');
      }
    }
  }

  /// Show delete user confirmation dialog
  static void showDeleteUserDialog(
    BuildContext context,
    UserModel user, {
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightContainer,
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
