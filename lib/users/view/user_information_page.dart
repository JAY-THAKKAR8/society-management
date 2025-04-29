import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/users/view/add_user_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class UserInformationPage extends StatefulWidget {
  final UserModel? user;

  const UserInformationPage({
    super.key,
    this.user,
  });

  @override
  State<UserInformationPage> createState() => _UserInformationPageState();
}

class _UserInformationPageState extends State<UserInformationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _currentUser;
  DashboardStatsModel? _societyStats;
  List<UserModel> _allUsers = [];
  Map<String, List<UserModel>> _lineUsers = {};
  Map<String, int> _lineMemberCounts = {};

  // Line-specific maintenance data
  double _lineCollectedAmount = 0.0;
  double _linePendingAmount = 0.0;
  int _pendingUsersCount = 0;
  int _fullyPaidUsersCount = 0;
  List<MaintenancePaymentModel> _linePayments = [];
  List<MaintenancePaymentModel> _fullyPaidPayments = [];
  List<MaintenancePeriodModel> _activePeriods = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = widget.user;
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // If user is not provided, get current user
      if (_currentUser == null) {
        final userRepository = getIt<IUserRepository>();
        final userResult = await userRepository.getCurrentUser();

        userResult.fold(
          (failure) {
            setState(() {
              _isLoading = false;
              _errorMessage = failure.message;
            });
            Utility.toast(message: failure.message);
          },
          (user) {
            setState(() {
              _currentUser = user;
            });
            _fetchSocietyStats();
            _fetchAllUsers();
            _fetchMaintenanceData();
          },
        );
      } else {
        _fetchSocietyStats();
        _fetchAllUsers();
        _fetchMaintenanceData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error fetching user data: $e');
    }
  }

  Future<void> _fetchMaintenanceData() async {
    if (_currentUser == null || _currentUser!.lineNumber == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final maintenanceRepository = getIt<IMaintenanceRepository>();

      // Get active maintenance periods
      final periodsResult = await maintenanceRepository.getActiveMaintenancePeriods();

      periodsResult.fold(
        (failure) {
          Utility.toast(message: failure.message);
          setState(() {
            _isLoading = false;
          });
        },
        (periods) async {
          _activePeriods = periods;

          if (periods.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Get the most recent period
          final latestPeriod = periods.first;
          if (latestPeriod.id == null) {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Get payments for the user's line
          final paymentsResult = await maintenanceRepository.getPaymentsForLine(
            periodId: latestPeriod.id!,
            lineNumber: _currentUser!.lineNumber!,
          );

          paymentsResult.fold(
            (failure) {
              Utility.toast(message: failure.message);
              setState(() {
                _isLoading = false;
              });
            },
            (payments) {
              // Calculate line-specific stats
              double totalCollected = 0.0;
              double totalPending = 0.0;
              int pendingCount = 0;
              int fullyPaidCount = 0;
              List<MaintenancePaymentModel> fullyPaid = [];

              for (final payment in payments) {
                final amount = payment.amount ?? 0.0;
                final amountPaid = payment.amountPaid;

                totalCollected += amountPaid;

                if (amountPaid >= amount && amount > 0) {
                  fullyPaidCount++;
                  fullyPaid.add(payment);
                } else if (amount > 0) {
                  pendingCount++;
                  totalPending += (amount - amountPaid);
                }
              }

              setState(() {
                _linePayments = payments;
                _lineCollectedAmount = totalCollected;
                _linePendingAmount = totalPending;
                _pendingUsersCount = pendingCount;
                _fullyPaidUsersCount = fullyPaidCount;
                _fullyPaidPayments = fullyPaid;
                _isLoading = false;
              });
            },
          );
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error fetching maintenance data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSocietyStats() async {
    try {
      final statsRepository = getIt<IDashboardStatsRepository>();
      final statsResult = await statsRepository.getDashboardStats();

      statsResult.fold(
        (failure) {
          Utility.toast(message: failure.message);
        },
        (stats) {
          setState(() {
            _societyStats = stats;
          });
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error fetching society stats: $e');
    }
  }

  Future<void> _fetchAllUsers() async {
    try {
      final userRepository = getIt<IUserRepository>();
      final usersResult = await userRepository.getAllUsers();

      usersResult.fold(
        (failure) {
          Utility.toast(message: failure.message);
          setState(() {
            _isLoading = false;
          });
        },
        (users) {
          // Filter out admin users
          final filteredUsers = users
              .where(
                  (user) => user.role != AppConstants.admin && user.role != 'ADMIN' && user.role != AppConstants.admins)
              .toList();

          // Group users by line
          final Map<String, List<UserModel>> lineUsers = {};
          final Map<String, int> lineCounts = {};

          for (final user in filteredUsers) {
            if (user.lineNumber != null) {
              if (!lineUsers.containsKey(user.lineNumber)) {
                lineUsers[user.lineNumber!] = [];
                lineCounts[user.lineNumber!] = 0;
              }
              lineUsers[user.lineNumber]!.add(user);
              lineCounts[user.lineNumber!] = (lineCounts[user.lineNumber] ?? 0) + 1;
            }
          }

          setState(() {
            _allUsers = filteredUsers;
            _lineUsers = lineUsers;
            _lineMemberCounts = lineCounts;
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

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      Utility.toast(message: 'Phone number not available');
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Utility.toast(message: 'Could not launch phone call');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Society Information',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
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
                        onPressed: _fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildUserProfileSection(),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Society Summary'),
                        Tab(text: 'Maintenance Details'),
                        Tab(text: 'Contact Directory'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSocietySummaryTab(),
                          _buildMaintenanceDetailsTab(),
                          _buildContactDirectoryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildUserProfileSection() {
    if (_currentUser == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.buttonColor.withOpacity(0.2),
                child: Text(
                  _currentUser!.name?.isNotEmpty == true ? _currentUser!.name![0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
                      _currentUser!.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser!.userRoleViewString,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.buttonColor,
                          ),
                    ),
                    if (_currentUser!.email != null)
                      Text(
                        _currentUser!.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.greyText,
                            ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.buttonColor),
                onPressed: () async {
                  if (_currentUser?.id != null) {
                    await context.push(AddUserPage(userId: _currentUser!.id));
                    _fetchData();
                  }
                },
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.home,
                  label: 'Villa Number',
                  value: _currentUser!.villNumber ?? 'N/A',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.linear_scale,
                  label: 'Line',
                  value: _currentUser!.userLineViewString,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.phone,
                  label: 'Mobile',
                  value: _currentUser!.mobileNumber ?? 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.greyText),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.greyText,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildSocietySummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSocietyStatsSection(),
          const SizedBox(height: 24),
          _buildLineMembersSection(),
        ],
      ),
    );
  }

  Widget _buildSocietyStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Society Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatCard(
                title: 'Total Society Members',
                value: _societyStats != null ? '${_societyStats!.totalMembers}' : '0',
                icon: Icons.people,
                color: Colors.blue,
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              _buildStatCard(
                title: 'Total Maintenance Collected',
                value: _societyStats != null ? '₹${_societyStats!.maintenanceCollected.toStringAsFixed(2)}' : '₹0.00',
                icon: Icons.payments,
                color: Colors.green,
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              _buildStatCard(
                title: 'Total Pending Amount',
                value: _societyStats != null ? '₹${_societyStats!.maintenancePending.toStringAsFixed(2)}' : '₹0.00',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              _buildStatCard(
                title: 'Total Expenses',
                value: _societyStats != null ? '₹${_societyStats!.totalExpenses.toStringAsFixed(2)}' : '₹0.00',
                icon: Icons.account_balance_wallet,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.greyText,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line-wise Members',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 1; i <= 5; i++)
                _buildLineRow(
                  lineNumber: i.toString(),
                  memberCount: _lineMemberCounts[AppConstants.getLineConstant(i)] ?? 0,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineRow({
    required String lineNumber,
    required int memberCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                lineNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.buttonColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Line $lineNumber',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$memberCount Members',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.buttonColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDirectoryTab() {
    // Group users by line for better organization
    return _allUsers.isEmpty
        ? const Center(child: Text('No members found'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final lineEntry in _lineUsers.entries) _buildLineContactSection(lineEntry.key, lineEntry.value),
            ],
          );
  }

  Widget _buildLineContactSection(String lineNumber, List<UserModel> users) {
    String lineText = 'Line ${_getLineText(lineNumber)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.buttonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, size: 18, color: AppColors.buttonColor),
              const SizedBox(width: 8),
              Text(
                lineText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.buttonColor,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${users.length} members)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.buttonColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...users.map((user) => _buildContactCard(user)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildContactCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.buttonColor.withOpacity(0.2),
              child: Text(
                user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.buttonColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
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
            if (user.mobileNumber != null && user.mobileNumber!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => _makePhoneCall(user.mobileNumber),
                tooltip: 'Call',
              ),
          ],
        ),
      ),
    );
  }

  String _getLineText(String lineNumber) {
    switch (lineNumber) {
      case AppConstants.firstLine:
        return '1';
      case AppConstants.secondLine:
        return '2';
      case AppConstants.thirdLine:
        return '3';
      case AppConstants.fourthLine:
        return '4';
      case AppConstants.fifthLine:
        return '5';
      default:
        return lineNumber;
    }
  }

  Widget _buildMaintenanceDetailsTab() {
    if (_currentUser == null || _currentUser!.lineNumber == null) {
      return const Center(child: Text('User information not available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineMaintenanceStats(),
          const SizedBox(height: 24),
          _buildPaymentStatusSection(),
          const SizedBox(height: 24),
          _buildActivePeriodsSection(),
        ],
      ),
    );
  }

  Widget _buildLineMaintenanceStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line ${_currentUser!.userLineViewString} Maintenance',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatCard(
                title: 'Collected Amount',
                value: '₹${_lineCollectedAmount.toStringAsFixed(2)}',
                icon: Icons.payments,
                color: Colors.green,
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              _buildStatCard(
                title: 'Pending Amount',
                value: '₹${_linePendingAmount.toStringAsFixed(2)}',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              _buildStatCard(
                title: 'Total Members',
                value: '${(_pendingUsersCount + _fullyPaidUsersCount)}',
                icon: Icons.people,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatCard(
                title: 'Pending Payments',
                value: '$_pendingUsersCount members',
                icon: Icons.warning_amber,
                color: Colors.orange,
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              _buildStatCard(
                title: 'Fully Paid',
                value: '$_fullyPaidUsersCount members',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),
        ),
        if (_fullyPaidUsersCount > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Fully Paid Members',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ..._fullyPaidPayments.map((payment) => _buildPaymentCard(payment)),
        ],
      ],
    );
  }

  Widget _buildPaymentCard(MaintenancePaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.green.withOpacity(0.2),
              child: const Icon(
                Icons.check,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.userName ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (payment.userVillaNumber != null)
                    Text(
                      'Villa: ${payment.userVillaNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.greyText,
                          ),
                    ),
                  Text(
                    'Paid: ₹${payment.amountPaid.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            if (payment.paymentDate != null)
              Text(
                _formatDate(payment.paymentDate!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.greyText,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildActivePeriodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Maintenance Periods',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStatCard(
                title: 'Active Periods',
                value: '${_activePeriods.length}',
                icon: Icons.calendar_month,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        if (_activePeriods.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._activePeriods.map((period) => _buildPeriodCard(period)),
        ],
      ],
    );
  }

  Widget _buildPeriodCard(MaintenancePeriodModel period) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period.name ?? 'Unnamed Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodInfo(
                    label: 'Start Date',
                    value: period.startDate != null ? _formatDate(period.startDate!) : 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildPeriodInfo(
                    label: 'End Date',
                    value: period.endDate != null ? _formatDate(period.endDate!) : 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodInfo(
                    label: 'Amount',
                    value: period.amount != null ? '₹${period.amount!.toStringAsFixed(2)}' : 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildPeriodInfo(
                    label: 'Due Date',
                    value: period.dueDate != null ? _formatDate(period.dueDate!) : 'N/A',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInfo({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.greyText,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
