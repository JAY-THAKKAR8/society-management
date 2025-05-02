import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/complaints/view/complaint_response_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';

class SimpleComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onRefresh;
  final Function(BuildContext, ComplaintModel) showDetailsDialog;

  const SimpleComplaintCard({
    super.key,
    required this.complaint,
    required this.onRefresh,
    required this.showDetailsDialog,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Format date safely
      String formattedDate = 'Unknown date';
      if (complaint.createdAt != null) {
        try {
          final date = DateTime.parse(complaint.createdAt!);
          formattedDate = DateFormat('MMM d, yyyy').format(date);
        } catch (e) {
          // Keep default value
        }
      }

      // Status color with safe default
      Color statusColor = Colors.grey; // Default color
      IconData statusIcon = Icons.help_outline; // Default icon

      try {
        switch (complaint.status) {
          case ComplaintStatus.pending:
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            break;
          case ComplaintStatus.inProgress:
            statusColor = Colors.blue;
            statusIcon = Icons.engineering;
            break;
          case ComplaintStatus.resolved:
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case ComplaintStatus.rejected:
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            // Use defaults
            break;
        }
      } catch (e) {
        // Use defaults if there's an issue with status
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: ThemeUtils.getContainerColor(context),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ThemeUtils.getHighlightColor(context, statusColor, opacity: 0.2)),
        ),
        child: InkWell(
          onTap: () async {
            try {
              if (complaint.status == ComplaintStatus.pending) {
                // For pending complaints, go to response page
                final result = await context.push(ComplaintResponsePage(complaint: complaint));
                if (result == true) {
                  onRefresh();
                }
              } else {
                // For other complaints, show a dialog with details
                showDetailsDialog(context, complaint);
              }
            } catch (e) {
              // Handle navigation errors
              Utility.toast(message: 'Error navigating: $e');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure the column doesn't try to be bigger than needed
            children: [
              // Header with status
              Container(
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      complaint.statusDisplayName,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      complaint.title ?? 'No title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      complaint.description ?? 'No description',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // User info - simplified to avoid layout issues
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ThemeUtils.getHighlightColor(context, ThemeUtils.getPrimaryColor(context)),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            complaint.userName?.isNotEmpty == true ? complaint.userName![0].toUpperCase() : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ThemeUtils.getPrimaryColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // User details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                complaint.userName ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (complaint.userVillaNumber != null || complaint.userLineNumber != null)
                                Text(
                                  'Villa: ${complaint.userVillaNumber ?? 'N/A'}, Line: ${_formatLineNumber(complaint.userLineNumber)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Image indicator - simplified
                        if (complaint.imageUrl != null)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.image,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),

                    // Admin response preview - simplified
                    if (complaint.status != ComplaintStatus.pending && complaint.adminResponse != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.comment, size: 14, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Response: ${complaint.adminResponse}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                    fontStyle: FontStyle.italic,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Action button for pending complaints - simplified
                    if (complaint.status == ComplaintStatus.pending) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final result = await context.push(ComplaintResponsePage(complaint: complaint));
                              if (result == true) {
                                onRefresh();
                              }
                            } catch (e) {
                              Utility.toast(message: 'Error navigating: $e');
                            }
                          },
                          icon: const Icon(Icons.reply, size: 16),
                          label: const Text('Respond'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeUtils.getPrimaryColor(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Fallback for any errors
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.red.withAlpha(50),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error displaying complaint: $e'),
        ),
      );
    }
  }

  String _formatLineNumber(String? lineNumber) {
    if (lineNumber == null) return 'N/A';

    switch (lineNumber) {
      case 'FIRST_LINE':
        return 'Line 1';
      case 'SECOND_LINE':
        return 'Line 2';
      case 'THIRD_LINE':
        return 'Line 3';
      case 'FOURTH_LINE':
        return 'Line 4';
      case 'FIFTH_LINE':
        return 'Line 5';
      default:
        // Handle case where lineNumber might contain underscores
        if (lineNumber.contains('_')) {
          final parts = lineNumber.split('_');
          if (parts.length > 1) {
            // Convert FIRST_LINE to First Line
            return parts
                .map((part) => part.isNotEmpty ? '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}' : '')
                .join(' ');
          }
        }
        return lineNumber;
    }
  }
}
