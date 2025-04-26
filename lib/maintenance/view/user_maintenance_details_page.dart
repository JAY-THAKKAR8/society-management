import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/model/maintenance_stats_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_app_bar.dart';

class UserMaintenanceDetailsPage extends StatelessWidget {
  final UserStatsModel user;
  final List<MaintenancePeriodModel> activePeriods;

  const UserMaintenanceDetailsPage({
    super.key,
    required this.user,
    required this.activePeriods,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'User Maintenance Details',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(context),
            const SizedBox(height: 24),
            Text(
              'Maintenance Payment Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPaymentStatusCards(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final totalPending = user.totalAmount - user.totalPaid;
    final hasPendingPayments = totalPending > 0;

    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasPendingPayments ? Colors.red.withAlpha(76) : Colors.green.withAlpha(76),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 24, color: AppColors.buttonColor),
                const SizedBox(width: 8),
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
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Line Number',
                    user.lineNumber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Due',
                    '₹${user.totalAmount.toStringAsFixed(0)}',
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
                    'Total Paid',
                    '₹${user.totalPaid.toStringAsFixed(0)}',
                    valueColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Pending',
                    '₹${totalPending.toStringAsFixed(0)}',
                    valueColor: Colors.red,
                  ),
                ),
              ],
            ),
            if (hasPendingPayments) ...[
              const SizedBox(height: 16),
              Text(
                'Pending Periods: ${user.pendingPeriods.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCards(BuildContext context) {
    // Create a map of all active periods
    final periodMap = <String, MaintenancePeriodModel>{};
    for (final period in activePeriods) {
      if (period.id != null) {
        periodMap[period.id!] = period;
      }
    }

    // Create a set of pending period IDs for quick lookup
    final pendingPeriodIds = user.pendingPeriods.map((p) => p.periodId).toSet();

    return Column(
      children: activePeriods.map((period) {
        if (period.id == null) return const SizedBox.shrink();

        final isPending = pendingPeriodIds.contains(period.id);
        final pendingPeriod = isPending ? user.pendingPeriods.firstWhere((p) => p.periodId == period.id) : null;

        final amount = period.amount ?? 0.0;
        final amountPaid = isPending ? pendingPeriod!.amountPaid : amount;
        final pendingAmount = amount - amountPaid;

        final dueDate =
            period.dueDate != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(period.dueDate!)) : 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColors.lightBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPending ? Colors.red.withAlpha(76) : Colors.green.withAlpha(76),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        period.name ?? 'Unnamed Period',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending ? Colors.red.withAlpha(25) : Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPending ? 'Pending' : 'Paid',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPending ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Amount',
                        '₹${amount.toStringAsFixed(0)}',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Paid',
                        '₹${amountPaid.toStringAsFixed(0)}',
                        valueColor: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Pending',
                        '₹${pendingAmount.toStringAsFixed(0)}',
                        valueColor: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date: $dueDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber,
                          ),
                    ),
                    if (isPending) ...[
                      const Gap(5),
                      Text(
                        'Please pay as soon as possible',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
