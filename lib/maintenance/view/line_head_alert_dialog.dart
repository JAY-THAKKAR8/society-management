import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/view/maintenance_payments_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class LineHeadAlertDialog extends StatelessWidget {
  final MaintenancePeriodModel period;
  final String lineNumber;
  final int pendingCount;
  final double pendingAmount;

  const LineHeadAlertDialog({
    super.key,
    required this.period,
    required this.lineNumber,
    required this.pendingCount,
    required this.pendingAmount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.amber.withAlpha(100),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Maintenance Alert',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Line $lineNumber has pending maintenance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Period:',
            period.name ?? 'Unnamed Period',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Pending Members:',
            '$pendingCount members',
            valueColor: Colors.red,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Total Due:',
            '₹${pendingAmount.toStringAsFixed(2)}',
            valueColor: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Please collect the pending maintenance from your line members as soon as possible.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Dismiss'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(MaintenancePaymentsPage(periodId: period.id!));
          },
          icon: const Icon(Icons.payments),
          label: const Text('View Payments'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.greyText,
              ),
        ),
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
