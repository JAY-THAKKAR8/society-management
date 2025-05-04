import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/settings/view/admin_settings_page.dart';
import 'package:society_management/settings/view/user_profile_page.dart';
import 'package:society_management/theme/theme_provider.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/screenshot_utility.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';
import 'package:society_management/widget/role_themed_card.dart';
import 'package:society_management/widget/theme_switcher.dart';

class CommonSettingsPage extends StatefulWidget {
  const CommonSettingsPage({super.key});

  @override
  State<CommonSettingsPage> createState() => _CommonSettingsPageState();
}

class _CommonSettingsPageState extends State<CommonSettingsPage> {
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isLineHead = false;
  bool _isLineMember = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final userRepository = getIt<IUserRepository>();
      final userResult = await userRepository.getCurrentUser();

      userResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
          });
          Utility.toast(message: failure.message);
        },
        (user) {
          setState(() {
            _currentUser = user;
            _isAdmin = user.role == AppConstants.admin;
            _isLineHead = user.isLineHead;
            _isLineMember = user.isLineMember;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Utility.toast(message: 'Error fetching user data: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService().signOut();
        if (mounted) {
          context.pushAndRemoveUntil(const LoginPage());
        }
      } catch (e) {
        Utility.toast(message: 'Error logging out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonGradientAppBar(
        title: 'Settings',
        gradientColors: _getGradientColors(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildThemeSection(context),
                const SizedBox(height: 24),
                _buildAccountSection(context),
                const SizedBox(height: 24),
                if (_isAdmin) ...[
                  _buildAdminSection(context),
                  const SizedBox(height: 24),
                ],
                if (_isLineHead) ...[
                  _buildLineHeadSection(context),
                  const SizedBox(height: 24),
                ],
                _buildToolsSection(context),
                const SizedBox(height: 24),
                _buildAboutSection(context),
              ],
            ),
    );
  }

  List<Color> _getGradientColors() {
    if (_isAdmin) {
      return AppColors.gradientBlueIndigo;
    } else if (_isLineHead) {
      return AppColors.gradientGreenTeal;
    } else {
      return AppColors.gradientPurplePink;
    }
  }

  Widget _buildThemeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        RoleThemedCard(
          userRole: _currentUser?.role,
          child: Column(
            children: [
              ListTile(
                leading: BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) {
                    return Icon(
                      state == ThemeState.dark ? Icons.dark_mode : Icons.light_mode,
                      color: state == ThemeState.dark ? AppColors.primaryOrange : AppColors.primaryBlue,
                    );
                  },
                ),
                title: const Text('Theme'),
                subtitle: const Text('Change app theme'),
                trailing: const ThemeSwitcher(showLabel: false),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.color_lens, color: AppColors.primaryPurple),
                title: const Text('Accent Color'),
                subtitle: const Text('Change app accent color'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'Coming soon!');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        RoleThemedCard(
          userRole: _currentUser?.role,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primaryBlue),
                title: const Text('Profile'),
                subtitle: const Text('View and edit your profile'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (_currentUser != null) {
                    context.push(UserProfilePage(user: _currentUser!));
                  } else {
                    Utility.toast(message: 'User profile not available');
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.security, color: AppColors.primaryGreen),
                title: const Text('Security'),
                subtitle: const Text('Change password and security settings'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'Coming soon!');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.primaryRed),
                title: const Text('Logout'),
                subtitle: const Text('Sign out from your account'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Admin Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryBlue,
                ),
          ),
        ),
        RoleThemedCard(
          userRole: _currentUser?.role,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: AppColors.primaryBlue),
                title: const Text('Admin Settings'),
                subtitle: const Text('Advanced settings for administrators'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push(const AdminSettingsPage());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('Clear App Data'),
                subtitle: const Text('Delete all app data except user accounts'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push(const AdminSettingsPage());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineHeadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Line Head Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                ),
          ),
        ),
        RoleThemedCard(
          userRole: _currentUser?.role,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.people, color: AppColors.primaryGreen),
                title: const Text('Line Members'),
                subtitle: const Text('Manage members in your line'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'Coming soon!');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.primaryTeal),
                title: const Text('Maintenance Reports'),
                subtitle: const Text('View detailed maintenance reports'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'Coming soon!');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Tools',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        RoleThemedCard(
          userRole: _currentUser?.role,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.screenshot_monitor, color: AppColors.primaryTeal),
                title: const Text('Take Screenshot'),
                subtitle: const Text('Capture and share the current screen'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScreenshotUtility.takeAndShareScreenshot(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications, color: AppColors.primaryOrange),
                title: const Text('Notification Settings'),
                subtitle: const Text('Manage your notification preferences'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'Coming soon!');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        RoleThemedCard(
          userRole: _currentUser?.role,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: AppColors.primaryTeal),
                title: const Text('About KDV Management'),
                subtitle: const Text('Version 1.0.0'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'KDV Management App');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help, color: AppColors.primaryOrange),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help with the app'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'Coming soon!');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
