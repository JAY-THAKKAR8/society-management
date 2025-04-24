import 'package:flutter/material.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/utility.dart';

class LineHeadUsersPage extends StatefulWidget {
  const LineHeadUsersPage({super.key});

  @override
  State<LineHeadUsersPage> createState() => _LineHeadUsersPageState();
}

class _LineHeadUsersPageState extends State<LineHeadUsersPage> {
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _currentUser;
  int _memberCount = 0;
  String? _lineHeadName;

  @override
  void initState() {
    super.initState();
    _getCurrentUserAndFetchData();
  }

  Future<void> _getCurrentUserAndFetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user
      final authService = AuthService();
      _currentUser = await authService.getCurrentUser();

      if (_currentUser == null || _currentUser!.lineNumber == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not determine your line number';
        });
        return;
      }

      // Fetch users for this line
      await _fetchUsers();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await getIt<IUserRepository>().getAllUsers();

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (users) {
          // Count members in this line and find line head
          _memberCount = 0;
          _lineHeadName = null;

          for (final user in users) {
            if (user.lineNumber == _currentUser!.lineNumber) {
              // Count non-admin users
              if (user.role != 'admin' && user.role != 'ADMIN' && user.role != AppConstants.admins) {
                _memberCount++;
              }

              // Check if this user is a line head
              if (user.role == AppConstants.lineLead) {
                _lineHeadName = user.name;
              }
            }
          }

          setState(() {
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

  Future<List<UserModel>> _fetchLineMembers() async {
    try {
      final result = await getIt<IUserRepository>().getAllUsers();

      return result.fold(
        (failure) {
          Utility.toast(message: failure.message);
          return [];
        },
        (users) {
          // Filter users for this line (excluding admins)
          return users
              .where((user) =>
                  user.lineNumber == _currentUser!.lineNumber &&
                  user.role != 'admin' &&
                  user.role != 'ADMIN' &&
                  user.role != AppConstants.admins)
              .toList();
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error fetching line members: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Members'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: 'Refresh members',
          ),
        ],
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
                        onPressed: _getCurrentUserAndFetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<List<UserModel>>(
                  future: _fetchLineMembers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading members: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final members = snapshot.data ?? [];

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Line Members',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildLineHeader(
                            context,
                            _getLineText(_currentUser?.lineNumber),
                            'Total Members: $_memberCount',
                            _lineHeadName,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: members.isEmpty
                                ? const Center(child: Text('No members found in your line'))
                                : ListView.builder(
                                    itemCount: members.length,
                                    itemBuilder: (context, index) {
                                      final member = members[index];
                                      return _buildMemberCard(context, member);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _getLineText(String? lineNumber) {
    switch (lineNumber) {
      case AppConstants.firstLine:
        return 'Line 1';
      case AppConstants.secondLine:
        return 'Line 2';
      case AppConstants.thirdLine:
        return 'Line 3';
      case AppConstants.fourthLine:
        return 'Line 4';
      case AppConstants.fifthLine:
        return 'Line 5';
      default:
        return 'Your Line';
    }
  }

  Widget _buildLineHeader(
    BuildContext context,
    String title,
    String subtitle,
    String? lineHeadName,
  ) {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.buttonColor.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.people,
                  color: AppColors.buttonColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.greyText,
                        ),
                  ),
                  if (lineHeadName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.buttonColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Line Head: $lineHeadName',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.buttonColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, UserModel member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.buttonColor.withAlpha(50),
              radius: 25,
              child: Text(
                member.name?.isNotEmpty == true ? member.name![0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.buttonColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (member.villNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Villa: ${member.villNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.greyText,
                          ),
                    ),
                  ],
                  if (member.mobileNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mobile: ${member.mobileNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.greyText,
                          ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${member.userRoleViewString}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: member.role == AppConstants.lineLead ? AppColors.buttonColor : AppColors.greyText,
                          fontWeight: member.role == AppConstants.lineLead ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
