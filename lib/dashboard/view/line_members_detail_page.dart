import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class LineMembersDetailPage extends StatefulWidget {
  final String lineNumber;
  final String lineDisplayName;

  const LineMembersDetailPage({
    super.key,
    required this.lineNumber,
    required this.lineDisplayName,
  });

  @override
  State<LineMembersDetailPage> createState() => _LineMembersDetailPageState();
}

class _LineMembersDetailPageState extends State<LineMembersDetailPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _lineMembers = [];
  UserModel? _lineHead;
  List<MaintenancePeriodModel> _periods = [];
  Map<String, List<MaintenancePaymentModel>> _paymentsByUser = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get all users in this line
      final userRepository = getIt<IUserRepository>();
      final usersResult = await userRepository.getAllUsers();

      await usersResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (users) async {
          // Filter users by line number
          final lineUsers = users
              .where((user) =>
                  user.lineNumber == widget.lineNumber &&
                  user.role != AppConstants.admin &&
                  user.role != 'admin' &&
                  user.role != 'ADMIN')
              .toList();

          // Find line head
          _lineHead = lineUsers.firstWhere(
            (user) => user.isLineHead,
            orElse: () => const UserModel(),
          );

          // Get all members (excluding admins)
          _lineMembers = lineUsers;

          // Get active maintenance periods
          final maintenanceRepository = getIt<IMaintenanceRepository>();
          final periodsResult = await maintenanceRepository.getActiveMaintenancePeriods();

          await periodsResult.fold(
            (failure) {
              Utility.toast(message: failure.message);
            },
            (periods) async {
              _periods = periods;

              if (periods.isNotEmpty) {
                // Get payments for the most recent period
                final latestPeriod = periods.first;
                final paymentsResult = await maintenanceRepository.getPaymentsForPeriod(
                  periodId: latestPeriod.id!,
                );

                paymentsResult.fold(
                  (failure) {
                    Utility.toast(message: failure.message);
                  },
                  (payments) {
                    // Group payments by user ID
                    _paymentsByUser = {};
                    for (final user in _lineMembers) {
                      if (user.id != null) {
                        final userPayments = payments.where((payment) => payment.userId == user.id).toList();
                        if (userPayments.isNotEmpty) {
                          _paymentsByUser[user.id!] = userPayments;
                        }
                      }
                    }
                  },
                );
              }

              setState(() {
                _isLoading = false;
              });
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error loading line members: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '${widget.lineDisplayName} Details',
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
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Welcome section
                    _buildWelcomeSection(),
                    const SizedBox(height: 16),

                    // Line head info card
                    if (_lineHead != null && _lineHead?.id != null) _buildLineHeadCard(),

                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Members'),
                        Tab(text: 'Maintenance'),
                      ],
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMembersTab(),
                          _buildMaintenanceTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLineHeadCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryBlue,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Line Head',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      Text(
                        _lineHead?.name ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_lineHead?.mobileNumber != null)
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () {
                      _makePhoneCall(_lineHead!.mobileNumber!);
                    },
                  ),
              ],
            ),
            if (_lineHead?.mobileNumber != null || _lineHead?.email != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (_lineHead?.mobileNumber != null) ...[
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(_lineHead?.mobileNumber ?? ''),
                      const SizedBox(width: 16),
                    ],
                    if (_lineHead?.email != null) ...[
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _lineHead?.email ?? '',
                        style: const TextStyle(fontSize: 12),
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

  Widget _buildMembersTab() {
    if (_lineMembers.isEmpty) {
      return const Center(
        child: Text('No members found in this line'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lineMembers.length,
      itemBuilder: (context, index) {
        final member = _lineMembers[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(UserModel member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: member.isLineHead ? Colors.amber : Colors.blue,
          child: Text(
            member.name?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          member.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.userRoleViewString),
            if (member.villNumber != null) Text('Villa: ${member.villNumber}'),
          ],
        ),
        trailing: member.mobileNumber != null
            ? IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () {
                  _makePhoneCall(member.mobileNumber!);
                },
              )
            : null,
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    if (_periods.isEmpty) {
      return const Center(
        child: Text('No active maintenance periods found'),
      );
    }

    final latestPeriod = _periods.first;

    return Column(
      children: [
        // Period info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: AppColors.lightBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latestPeriod.name ?? 'Current Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (latestPeriod.startDate != null && latestPeriod.endDate != null)
                    Text(
                      'Period: ${_formatDate(latestPeriod.startDate!)} to ${_formatDate(latestPeriod.endDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (latestPeriod.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Due Date: ${_formatDate(latestPeriod.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Payment status tabs
        DefaultTabController(
          length: 3,
          child: Expanded(
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Paid'),
                    Tab(text: 'Pending'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPaymentsList(latestPeriod, filter: 'all'),
                      _buildPaymentsList(latestPeriod, filter: 'paid'),
                      _buildPaymentsList(latestPeriod, filter: 'pending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsList(MaintenancePeriodModel period, {required String filter}) {
    // Filter members based on payment status
    List<UserModel> filteredMembers = [];

    for (final member in _lineMembers) {
      if (member.id == null) continue;

      final payments = _paymentsByUser[member.id] ?? [];
      final payment = payments.isNotEmpty ? payments.first : null;

      if (filter == 'all') {
        filteredMembers.add(member);
      } else if (filter == 'paid' && payment != null && payment.status == PaymentStatus.paid) {
        filteredMembers.add(member);
      } else if (filter == 'pending' && (payment == null || payment.status != PaymentStatus.paid)) {
        filteredMembers.add(member);
      }
    }

    if (filteredMembers.isEmpty) {
      return Center(
        child: Text('No ${filter == 'paid' ? 'paid' : 'pending'} members found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final payments = _paymentsByUser[member.id] ?? [];
        final payment = payments.isNotEmpty ? payments.first : null;

        return _buildPaymentCard(member, payment, period);
      },
    );
  }

  Widget _buildPaymentCard(UserModel member, MaintenancePaymentModel? payment, MaintenancePeriodModel period) {
    final amount = period.amount ?? 0.0;
    final amountPaid = payment?.amountPaid ?? 0.0;
    final isPaid = payment != null && payment.status == PaymentStatus.paid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPaid ? Colors.green : Colors.orange,
                  radius: 16,
                  child: Icon(
                    isPaid ? Icons.check : Icons.pending,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withAlpha(50) : Colors.orange.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Paid',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '₹${amountPaid.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            if (payment?.paymentDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Payment Date: ${_formatDate(payment!.paymentDate!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      Utility.toast(message: 'Could not launch phone call');
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC850C0).withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.lineDisplayName} Members',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View all members and maintenance details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
