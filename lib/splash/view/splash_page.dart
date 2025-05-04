import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/auth/view/login_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/view/fixed_line_head_dashboard.dart';
import 'package:society_management/dashboard/view/fixed_line_member_dashboard.dart';
import 'package:society_management/dashboard/view/improved_admin_dashboard_with_screenshot.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/kdv_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Delay for 2 seconds to show splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check if user is already logged in
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // Get current user data to verify Firebase session is still valid
        final user = await _authService.getCurrentUser();

        if (user != null) {
          // User is logged in and Firebase session is valid
          if (mounted) {
            // First navigate to user information page
            await context.push(UserInformationPage(user: user));

            if (!mounted) return;

            // Then route based on user role
            if (user.role == AppConstants.lineMember) {
              context.pushAndRemoveUntil(const ImprovedLineMemberDashboard());
            } else if (user.role == AppConstants.lineLead) {
              context.pushAndRemoveUntil(const ImprovedLineHeadDashboard());
            } else if (user.role == AppConstants.lineHeadAndMember) {
              // For combined role, default to Line Head dashboard
              // User can choose different dashboard on next login
              context.pushAndRemoveUntil(const ImprovedLineHeadDashboard());
            } else {
              context.pushAndRemoveUntil(const ImprovedAdminDashboardWithScreenshot());
            }
          }
        } else {
          // Firebase session expired, clear login state and go to login page
          await _authService.clearLoginState();
          if (mounted) {
            context.pushAndRemoveUntil(const LoginPage());
          }
        }
      } else {
        // User is not logged in, go to login page
        if (mounted) {
          context.pushAndRemoveUntil(const LoginPage());
        }
      }
    } catch (e) {
      // Error occurred, go to login page
      Utility.toast(message: 'Error checking login status: $e');
      if (mounted) {
        context.pushAndRemoveUntil(const LoginPage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withBlue(60),
              AppColors.primary.withBlue(100),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom KDV Logo with glow effect
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.buttonColor.withAlpha(75),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const KDVLogo(
                  size: 120,
                  primaryColor: AppColors.buttonColor,
                  secondaryColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // App name
              const Text(
                'KDV Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              // App subtitle
              Text(
                'Society Management System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withAlpha(180),
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
