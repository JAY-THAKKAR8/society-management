import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/dashboard_page.dart';
import 'package:society_management/dashboard/line_head_dashboard.dart';
import 'package:society_management/dashboard/line_member_dashboard.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/view/user_information_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_button.dart';
import 'package:society_management/widget/kdv_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showRoleSelectionDialog(UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Dashboard'),
          content: const Text(
              'You have access to both Line Head and Line Member dashboards. Please select which one you want to use:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushAndRemoveUntil(const LineHeadDashboard());
              },
              child: const Text('Line Head Dashboard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushAndRemoveUntil(const LineMemberDashboard());
              },
              child: const Text('Line Member Dashboard'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result.isSuccess) {
            // Navigate based on user role
            if (result.user != null) {
              // Show user information page first
              await context.push(UserInformationPage(user: result.user));

              // Check if widget is still mounted before proceeding
              if (!mounted) return;

              // Then navigate to the appropriate dashboard
              if (result.user!.role == AppConstants.lineMember) {
                // Line member dashboard
                context.pushAndRemoveUntil(const LineMemberDashboard());
              } else if (result.user!.role == AppConstants.lineLead) {
                // Line head dashboard
                context.pushAndRemoveUntil(const LineHeadDashboard());
              } else if (result.user!.role == AppConstants.lineHeadAndMember) {
                // Show dialog to choose dashboard
                _showRoleSelectionDialog(result.user!);
              } else {
                // Admin dashboard
                context.pushAndRemoveUntil(const AdminDashboard());
              }

              // Show welcome message with role information
              Utility.toast(
                  message: 'Welcome ${result.user!.name}, you are logged in as ${result.user!.userRoleViewString}');
            } else {
              // Default to admin dashboard if user data is missing
              context.pushAndRemoveUntil(const AdminDashboard());
            }
          } else {
            Utility.toast(message: result.errorMessage ?? 'Login failed');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Utility.toast(message: 'Error: $e');
        }
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Custom KDV Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.buttonColor.withAlpha(50),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const KDVLogo(
                        size: 80,
                        primaryColor: AppColors.buttonColor,
                        secondaryColor: Colors.white,
                      ),
                    ),
                    const Gap(30),

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
                    const Gap(10),

                    // App subtitle
                    Text(
                      'Login to your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                    const Gap(40),

                    // Email field
                    AppTextFormField(
                      controller: _emailController,
                      title: 'Email',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const Gap(20),

                    // Password field
                    AppTextFormField(
                      controller: _passwordController,
                      title: 'Password',
                      hintText: 'Enter your password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const Gap(10),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                          Utility.toast(message: 'Contact admin to reset password');
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.buttonColor,
                          ),
                        ),
                      ),
                    ),
                    const Gap(30),

                    // Login button
                    CommonButton(
                      text: 'Login',
                      isLoading: _isLoading,
                      onTap: _login,
                    ),
                    const Gap(20),

                    // Default admin credentials
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withAlpha(40),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Default Admin Credentials',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Email: admin@kdv.com\nPassword: admin123',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
