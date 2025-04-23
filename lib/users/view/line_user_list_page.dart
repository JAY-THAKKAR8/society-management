import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/cubit/refresh_cubit.dart';
import 'package:society_management/enums/enum_file.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/users/view/add_user_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';

class LineUserListPage extends StatefulWidget {
  final String lineNumber;

  const LineUserListPage({
    super.key,
    required this.lineNumber,
  });

  @override
  State<LineUserListPage> createState() => _LineUserListPageState();
}

class _LineUserListPageState extends State<LineUserListPage> {
  bool _isLoading = true;
  List<UserModel> _users = [];
  String? _errorMessage;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for refresh events
    final state = context.watch<RefreshCubit>().state;
    if (state is ModifyUser) {
      if (state.user.lineNumber == widget.lineNumber) {
        _fetchUsers();
      }
    }
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
          // Filter users by line number
          final filteredUsers = users
              .where(
                (user) => user.lineNumber == widget.lineNumber,
              )
              .toList();

          setState(() {
            _users = filteredUsers;
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

  String _getLineTitle() {
    switch (widget.lineNumber) {
      case 'FIRST_LINE':
        return 'Line 1 Members';
      case 'SECOND_LINE':
        return 'Line 2 Members';
      case 'THIRD_LINE':
        return 'Line 3 Members';
      case 'FOURTH_LINE':
        return 'Line 4 Members';
      case 'FIFTH_LINE':
        return 'Line 5 Members';
      default:
        return 'Line Members';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getLineTitle()),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: 'Refresh users',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add user page
          await context.push(
            const AddUserPage(),
          );
          _fetchUsers();
        },
        backgroundColor: AppColors.buttonColor,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.greyText,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No members found in this line',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add members to this line to see them here',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.greyText,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(context, user);
                      },
                    ),
    );
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context, UserModel user) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.lightBlack,
            title: Text(
              'Delete User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            content: Text(
              'Are you sure you want to delete ${user.name}? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Delete user
  Future<void> _deleteUser(UserModel user) async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final userRepository = getIt<IUserRepository>();
      final result = await userRepository.deleteCustomer(userId: user.id!);

      result.fold(
        (failure) {
          Utility.toast(message: failure.message);
        },
        (_) {
          Utility.toast(message: 'User deleted successfully');
          context.read<RefreshCubit>().modifyUser(user, UserAction.delete);
          _fetchUsers();
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error deleting user: $e');
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  // Edit user
  void _editUser(UserModel user) async {
    await context.push(AddUserPage(userId: user.id));
    _fetchUsers();
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final bool isLineHead = user.role == AppConstants.lineLead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isLineHead ? AppColors.lightBlack.withBlue(40) : AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLineHead ? Colors.blue.withAlpha(100) : Colors.white.withAlpha(25),
          width: isLineHead ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isLineHead ? Colors.blue.withAlpha(50) : AppColors.buttonColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user.name?.isNotEmpty == true ? user.name!.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLineHead ? Colors.blue : AppColors.buttonColor,
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
                              color: isLineHead ? Colors.blue : null,
                            ),
                      ),
                      if (user.villNumber != null)
                        Text(
                          'Villa: ${user.villNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.greyText,
                              ),
                        ),
                      if (user.mobileNumber != null)
                        Text(
                          'Mobile: ${user.mobileNumber}',
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
                    color: isLineHead ? Colors.blue.withAlpha(50) : AppColors.buttonColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.userRoleViewString,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLineHead ? Colors.blue : AppColors.buttonColor,
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
                  onPressed: () => _editUser(user),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await _showDeleteConfirmation(context, user);
                    if (confirm) {
                      await _deleteUser(user);
                    }
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
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
}
