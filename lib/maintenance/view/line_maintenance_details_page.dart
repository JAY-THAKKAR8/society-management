import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/model/maintenance_stats_model.dart';
import 'package:society_management/maintenance/view/user_maintenance_details_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_app_bar.dart';

class LineMaintenanceDetailsPage extends StatefulWidget {
  final String lineNumber;
  final List<UserStatsModel> users;
  final List<MaintenancePeriodModel> activePeriods;

  const LineMaintenanceDetailsPage({
    super.key,
    required this.lineNumber,
    required this.users,
    required this.activePeriods,
  });

  @override
  State<LineMaintenanceDetailsPage> createState() => _LineMaintenanceDetailsPageState();
}

class _LineMaintenanceDetailsPageState extends State<LineMaintenanceDetailsPage> {
  String _searchQuery = '';
  late List<UserStatsModel> _filteredUsers;

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.users;
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = widget.users;
      } else {
        _filteredUsers = widget.users.where((user) {
          final nameMatch = user.userName.toLowerCase().contains(query.toLowerCase());
          final villaMatch = user.villaNumber?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || villaMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Line ${widget.lineNumber} Details',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(
                    child: Text('No users found'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(_filteredUsers[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or villa number',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          filled: true,
          fillColor: AppColors.lightBlack,
        ),
        onChanged: _filterUsers,
      ),
    );
  }

  Widget _buildUserCard(UserStatsModel user) {
    final hasPendingPayments = user.pendingPeriods.isNotEmpty;
    final totalPending = user.totalAmount - user.totalPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasPendingPayments ? Colors.red.withAlpha(76) : Colors.green.withAlpha(76),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to user details page
          context.push(
            UserMaintenanceDetailsPage(
              user: user,
              activePeriods: widget.activePeriods,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (user.villaNumber != null)
                          Text(
                            'Villa: ${user.villaNumber}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasPendingPayments ? Colors.red.withAlpha(25) : Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasPendingPayments ? 'Pending' : 'Fully Paid',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasPendingPayments ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total Due',
                      '₹${user.totalAmount.toStringAsFixed(0)}',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Paid',
                      '₹${user.totalPaid.toStringAsFixed(0)}',
                      valueColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Pending',
                      '₹${totalPending.toStringAsFixed(0)}',
                      valueColor: Colors.red,
                    ),
                  ),
                ],
              ),
              if (hasPendingPayments) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Pending Payments:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...user.pendingPeriods.map((period) {
                  final dueDate = period.dueDate != null ? DateFormat('MMM d, yyyy').format(period.dueDate!) : 'N/A';
                  final pendingAmount = period.amount - period.amountPaid;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(period.periodName),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '₹${pendingAmount.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Due: $dueDate',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.amber,
                                ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to user details page
                    context.push(
                      UserMaintenanceDetailsPage(
                        user: user,
                        activePeriods: widget.activePeriods,
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.greyText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

class _UserStats {
  final String userId;
  final String userName;
  final String? villaNumber;
  final String lineNumber;
  final double totalAmount;
  final double totalPaid;
  final List<_PendingPeriod> pendingPeriods;

  _UserStats({
    required this.userId,
    required this.userName,
    required this.villaNumber,
    required this.lineNumber,
    required this.totalAmount,
    required this.totalPaid,
    required this.pendingPeriods,
  });
}

class _PendingPeriod {
  final String periodId;
  final String periodName;
  final double amount;
  final double amountPaid;
  final DateTime? dueDate;

  _PendingPeriod({
    required this.periodId,
    required this.periodName,
    required this.amount,
    required this.amountPaid,
    required this.dueDate,
  });
}
