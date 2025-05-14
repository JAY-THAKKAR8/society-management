import 'package:flutter/material.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/service/maintenance_update_service.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_button.dart';

/// A page to fix line inconsistencies for users
class FixLineInconsistenciesPage extends StatefulWidget {
  const FixLineInconsistenciesPage({super.key});

  @override
  State<FixLineInconsistenciesPage> createState() => _FixLineInconsistenciesPageState();
}

class _FixLineInconsistenciesPageState extends State<FixLineInconsistenciesPage> {
  final _userRepository = getIt<IUserRepository>();
  bool _isLoading = true;
  bool _isProcessing = false;
  List<UserModel> _users = [];
  String? _errorMessage;
  String? _successMessage;
  final Map<String, bool> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _userRepository.getAllUsers();

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

            // Initialize selection map
            for (final user in users) {
              if (user.id != null) {
                _selectedUsers[user.id!] = false;
              }
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching users: $e';
      });
      Utility.toast(message: 'Error fetching users: $e');
    }
  }

  Future<void> _fixSelectedUsers() async {
    try {
      setState(() {
        _isProcessing = true;
        _successMessage = null;
        _errorMessage = null;
      });

      // Get selected user IDs
      final selectedUserIds = _selectedUsers.entries.where((entry) => entry.value).map((entry) => entry.key).toList();

      if (selectedUserIds.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No users selected';
        });
        Utility.toast(message: 'Please select at least one user');
        return;
      }

      // Fix inconsistencies for each selected user
      int fixedCount = 0;
      for (final userId in selectedUserIds) {
        await MaintenanceUpdateService.fixUserLineInconsistencies(userId);
        fixedCount++;
      }

      setState(() {
        _isProcessing = false;
        _successMessage = 'Fixed line inconsistencies for $fixedCount users';

        // Reset selections
        for (final key in _selectedUsers.keys) {
          _selectedUsers[key] = false;
        }
      });

      Utility.toast(message: 'Fixed line inconsistencies for $fixedCount users');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error fixing inconsistencies: $e';
      });
      Utility.toast(message: 'Error fixing inconsistencies: $e');
    }
  }

  Future<void> _fixAllUsers() async {
    try {
      setState(() {
        _isProcessing = true;
        _successMessage = null;
        _errorMessage = null;
      });

      // Fix inconsistencies for all users
      await MaintenanceUpdateService.fixAllUserLineInconsistencies();

      setState(() {
        _isProcessing = false;
        _successMessage = 'Fixed line inconsistencies for all users';

        // Reset selections
        for (final key in _selectedUsers.keys) {
          _selectedUsers[key] = false;
        }
      });

      Utility.toast(message: 'Fixed line inconsistencies for all users');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error fixing inconsistencies: $e';
      });
      Utility.toast(message: 'Error fixing inconsistencies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Line Inconsistencies'),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Info card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.blue.withAlpha(25),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Line Inconsistency Fixer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This tool fixes inconsistencies when a user\'s line number has been changed but their maintenance payments, complaints, events, or expenses still show the old line number.',
                    style: TextStyle(fontSize: 14),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: CommonButton(
                  onTap: _isProcessing ? null : _fixSelectedUsers,
                  text: 'Fix Selected Users',
                  icon: const Icon(Icons.build),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CommonButton(
                  onTap: _isProcessing ? null : _fixAllUsers,
                  text: 'Fix All Users',
                  icon: const Icon(Icons.build_circle),
                ),
              ),
            ],
          ),
        ),

        // Processing indicator
        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // User list
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    if (user.id == null) return const SizedBox.shrink();

                    return CheckboxListTile(
                      title: Text(user.name ?? 'Unknown'),
                      subtitle: Text(
                        'Line: ${user.lineNumber ?? 'None'}, Villa: ${user.villNumber ?? 'None'}, Role: ${user.role ?? 'Unknown'}',
                      ),
                      value: _selectedUsers[user.id] ?? false,
                      onChanged: _isProcessing
                          ? null
                          : (value) {
                              setState(() {
                                _selectedUsers[user.id!] = value ?? false;
                              });
                            },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
