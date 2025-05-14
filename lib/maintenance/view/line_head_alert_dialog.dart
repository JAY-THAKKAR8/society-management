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

  String _getMonthName(int month) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Format the due date if available
    String dueDate = 'N/A';
    if (period.dueDate != null) {
      try {
        final dateTime = DateTime.parse(period.dueDate!);
        dueDate = '${dateTime.day} ${_getMonthName(dateTime.month)}, ${dateTime.year}';
      } catch (e) {
        dueDate = 'Invalid date';
      }
    }

    return Dialog(
      backgroundColor: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.amber.withAlpha(100),
          width: 1.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance Alert',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Line $lineNumber has pending maintenance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[300],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Period details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withAlpha(75)),
              ),
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
                      const Icon(Icons.calendar_today, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Due Date: $dueDate',
                        style: const TextStyle(color: Colors.amber),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Pending Members',
                    '$pendingCount',
                    Icons.people,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Due',
                    '₹${pendingAmount.toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please collect the pending maintenance from your line members as soon as possible.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade200,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(
                      MaintenancePaymentsPage(
                        periodId: period.id!,
                        initialLineFilter: lineNumber,
                        initialStatusFilter: 'pending',
                      ),
                    );
                  },
                  icon: const Icon(Icons.payments, size: 18),
                  label: const Text('View Payments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
