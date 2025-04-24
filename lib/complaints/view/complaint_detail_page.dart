import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_app_bar.dart';

class ComplaintDetailPage extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintDetailPage({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    // Format dates
    String formattedCreatedDate = 'Unknown date';
    String formattedUpdatedDate = 'Unknown date';
    
    if (complaint.createdAt != null) {
      try {
        final date = DateTime.parse(complaint.createdAt!);
        formattedCreatedDate = DateFormat('MMM d, yyyy, h:mm a').format(date);
      } catch (e) {
        // Use default value
      }
    }
    
    if (complaint.updatedAt != null) {
      try {
        final date = DateTime.parse(complaint.updatedAt!);
        formattedUpdatedDate = DateFormat('MMM d, yyyy, h:mm a').format(date);
      } catch (e) {
        // Use default value
      }
    }

    // Status color
    Color statusColor;
    switch (complaint.status) {
      case ComplaintStatus.pending:
        statusColor = Colors.orange;
        break;
      case ComplaintStatus.inProgress:
        statusColor = Colors.blue;
        break;
      case ComplaintStatus.resolved:
        statusColor = Colors.green;
        break;
      case ComplaintStatus.rejected:
        statusColor = Colors.red;
        break;
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Complaint Details',
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
            _buildStatusCard(context, statusColor),
            const SizedBox(height: 16),
            _buildComplaintDetailsCard(context, formattedCreatedDate, formattedUpdatedDate),
            if (complaint.adminResponse != null) ...[
              const SizedBox(height: 16),
              _buildAdminResponseCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Color statusColor) {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(),
                color: statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaint.statusDisplayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
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

  IconData _getStatusIcon() {
    switch (complaint.status) {
      case ComplaintStatus.pending:
        return Icons.hourglass_empty;
      case ComplaintStatus.inProgress:
        return Icons.engineering;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }

  Widget _buildComplaintDetailsCard(BuildContext context, String createdDate, String updatedDate) {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complaint Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Title', complaint.title ?? 'No title'),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Description', complaint.description ?? 'No description', isMultiLine: true),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Submitted by', complaint.userName ?? 'Unknown'),
            if (complaint.userVillaNumber != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, 'Villa Number', complaint.userVillaNumber!),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Submitted on', createdDate),
            if (complaint.updatedAt != null && complaint.updatedAt != complaint.createdAt) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, 'Last updated', updatedDate),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminResponseCard(BuildContext context) {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.comment,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin Response',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              complaint.adminResponse!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isMultiLine ? FontWeight.normal : FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
