import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/users/view/add_user_page.dart';
import 'package:society_management/users/widget/user_list_widget.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/user_action_dialog.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Using ValueNotifiers for better performance and cleaner state management
  final isLoading = ValueNotifier<bool>(false);
  final usersList = ValueNotifier<List<UserModel>>([]);
  final errorMessage = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    isLoading.dispose();
    usersList.dispose();
    errorMessage.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      // Update loading state
      isLoading.value = true;
      errorMessage.value = null;

      final failOrSuccess = await getIt<IUserRepository>().getAllUsers();

      failOrSuccess.fold(
        (failure) {
          isLoading.value = false;
          errorMessage.value = failure.message;
          Utility.toast(message: failure.message);
        },
        (users) {
          usersList.value = users;
          isLoading.value = false;
        },
      );
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
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
      body: UserListWidget(
        isLoading: isLoading,
        users: usersList,
        errorMessage: errorMessage,
        onRetry: _fetchUsers,
        onResetPassword: (user) => _showResetPasswordDialog(context, user),
      ),
    );
  }

  /// Show reset password dialog using the reusable dialog widget
  void _showResetPasswordDialog(BuildContext context, UserModel user) {
    UserActionDialog.showResetPasswordDialog(
      context,
      user,
      onSuccess: _fetchUsers,
    );
  }
}
