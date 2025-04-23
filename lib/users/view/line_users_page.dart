import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/users/view/line_user_list_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';

class LineUsersPage extends StatefulWidget {
  const LineUsersPage({super.key});

  @override
  State<LineUsersPage> createState() => _LineUsersPageState();
}

class _LineUsersPageState extends State<LineUsersPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Map to store line member counts
  final Map<String, int> _lineMemberCounts = {};

  // Map to store line heads
  final Map<String, UserModel?> _lineHeads = {};

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
          // Reset counts and heads
          _lineMemberCounts.clear();
          _lineHeads.clear();

          // Initialize counts for all lines
          _lineMemberCounts[AppConstants.firstLine] = 0;
          _lineMemberCounts[AppConstants.secondLine] = 0;
          _lineMemberCounts[AppConstants.thirdLine] = 0;
          _lineMemberCounts[AppConstants.fourthLine] = 0;
          _lineMemberCounts[AppConstants.fifthLine] = 0;

          // Count members per line and find line heads
          for (final user in users) {
            final lineNumber = user.lineNumber;
            if (lineNumber != null) {
              // Increment count for this line
              _lineMemberCounts[lineNumber] = (_lineMemberCounts[lineNumber] ?? 0) + 1;

              // Check if this user is a line head
              if (user.role == AppConstants.lineLead) {
                _lineHeads[lineNumber] = user;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Lines'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: 'Refresh lines',
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
                        onPressed: _fetchUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a Line',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildLineItem(
                              context,
                              'Line 1',
                              'Total Members: ${_lineMemberCounts[AppConstants.firstLine] ?? 0}',
                              AppConstants.firstLine,
                              _lineHeads[AppConstants.firstLine]?.name,
                            ),
                            _buildLineItem(
                              context,
                              'Line 2',
                              'Total Members: ${_lineMemberCounts[AppConstants.secondLine] ?? 0}',
                              AppConstants.secondLine,
                              _lineHeads[AppConstants.secondLine]?.name,
                            ),
                            _buildLineItem(
                              context,
                              'Line 3',
                              'Total Members: ${_lineMemberCounts[AppConstants.thirdLine] ?? 0}',
                              AppConstants.thirdLine,
                              _lineHeads[AppConstants.thirdLine]?.name,
                            ),
                            _buildLineItem(
                              context,
                              'Line 4',
                              'Total Members: ${_lineMemberCounts[AppConstants.fourthLine] ?? 0}',
                              AppConstants.fourthLine,
                              _lineHeads[AppConstants.fourthLine]?.name,
                            ),
                            _buildLineItem(
                              context,
                              'Line 5',
                              'Total Members: ${_lineMemberCounts[AppConstants.fifthLine] ?? 0}',
                              AppConstants.fifthLine,
                              _lineHeads[AppConstants.fifthLine]?.name,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLineItem(
    BuildContext context,
    String title,
    String subtitle,
    String lineConstant,
    String? lineHeadName,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: InkWell(
        onTap: () {
          context.push(LineUserListPage(lineNumber: lineConstant));
        },
        borderRadius: BorderRadius.circular(12),
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
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'No Line Head Assigned',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
