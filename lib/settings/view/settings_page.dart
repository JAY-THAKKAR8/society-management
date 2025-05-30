import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/settings/view/admin_settings_page.dart';
import 'package:society_management/theme/theme_provider.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_card.dart';
import 'package:society_management/widget/common_gradient_app_bar.dart';
import 'package:society_management/widget/theme_switcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    try {
      final userRepository = getIt<IUserRepository>();
      final userResult = await userRepository.getCurrentUser();

      userResult.fold(
        (failure) {
          setState(() {
            _isAdmin = false;
            _isLoading = false;
          });
        },
        (user) {
          setState(() {
            _isAdmin = user.role == AppConstants.admin || user.role == 'ADMIN' || user.role?.toLowerCase() == 'admin';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      Utility.toast(message: 'Error checking admin status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonGradientAppBar(
        title: 'Settings',
        gradientColors: AppColors.gradientPurpleBlue,
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
                _buildAboutSection(context),
              ],
            ),
    );
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
        CommonCard(
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
        CommonCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primaryBlue),
                title: const Text('Profile'),
                subtitle: const Text('View and edit your profile'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Utility.toast(message: 'Coming soon!');
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
        CommonCard(
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
        CommonCard(
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

  Future<void> _logout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.signOut();
      if (context.mounted) {
        context.pushAndRemoveUntil(const LoginPage());
      }
    } catch (e) {
      Utility.toast(message: 'Error logging out: $e');
    }
  }
}
