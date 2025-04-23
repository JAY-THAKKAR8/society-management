import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:society_management/auth/repository/auth_repository.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/users/view/add_user_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_drop_down_widget.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';
import 'package:society_management/injector/injector.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<UserModel> _users = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userRepository = getIt<IUserRepository>();
      final result = await userRepository.getAllUsers();

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (users) {
          setState(() {
            _users = users;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'User Management',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddUserPage instead of showing dialog
          await context.push(const AddUserPage());
          // Refresh the user list when returning from AddUserPage
          if (mounted) {
            _fetchUsers();
          }
        },
        backgroundColor: AppColors.buttonColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Users'),
              Tab(text: 'Add User'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(),
                _buildAddUserForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text('No users found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(context, user);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final bool isAdmin = user.role == AppConstants.admin;
    final bool isLineHead = user.role == AppConstants.lineLead;
    
    Color roleColor;
    if (isAdmin) {
      roleColor = Colors.red;
    } else if (isLineHead) {
      roleColor = Colors.blue;
    } else {
      roleColor = AppColors.buttonColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAdmin ? Colors.red.withAlpha(100) : 
                 isLineHead ? Colors.blue.withAlpha(100) : 
                 Colors.white.withAlpha(25),
          width: isAdmin || isLineHead ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user.name?.isNotEmpty == true ? user.name!.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (user.email != null)
                        Text(
                          user.email!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.greyText,
                              ),
                        ),
                      if (user.villNumber != null)
                        Text(
                          'Villa: ${user.villNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.greyText,
                              ),
                        ),
                      if (user.lineNumber != null)
                        Text(
                          'Line: ${user.userLineViewString}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.greyText,
                              ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.userRoleViewString,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                TextButton.icon(
                  onPressed: () async {
                    await context.push(AddUserPage(userId: user.id));
                    if (mounted) {
                      _fetchUsers();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Reset Password button
                TextButton.icon(
                  onPressed: () {
                    _showResetPasswordDialog(context, user);
                  },
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: const Text('Reset Password'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddUserForm() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Use the + button to add a new user'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await context.push(const AddUserPage());
              // Refresh the user list when returning from AddUserPage
              if (mounted) {
                _fetchUsers();
                // Switch to the users list tab
                _tabController.animateTo(0);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, UserModel user) {
    final passwordController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.lightBlack,
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
                          if (passwordController.text.length < 6) {
                            Utility.toast(message: 'Password must be at least 6 characters');
                            return;
                          }
                          
                          setState(() {
                            isLoading = true;
                          });
                          
                          try {
                            // TODO: Implement password reset functionality
                            await Future.delayed(const Duration(seconds: 1));
                            
                            if (mounted) {
                              Navigator.of(context).pop();
                              Utility.toast(message: 'Password reset successfully');
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                isLoading = false;
                              });
                              Utility.toast(message: 'Error: $e');
                            }
                          }
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
}
