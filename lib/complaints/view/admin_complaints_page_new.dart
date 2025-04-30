import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/complaints/view/complaint_response_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class AdminComplaintsPageNew extends StatefulWidget {
  const AdminComplaintsPageNew({super.key});

  @override
  State<AdminComplaintsPageNew> createState() => _AdminComplaintsPageNewState();
}

class _AdminComplaintsPageNewState extends State<AdminComplaintsPageNew> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ComplaintModel> _allComplaints = [];
  List<ComplaintModel> _filteredComplaints = [];

  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Resolved', 'Rejected'];
  final Map<String, Color> _filterColors = {
    'All': AppColors.buttonColor,
    'Pending': Colors.orange,
    'In Progress': Colors.blue,
    'Resolved': Colors.green,
    'Rejected': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final complaintRepository = getIt<IComplaintRepository>();
      final result = await complaintRepository.getAllComplaints();

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (complaints) {
          setState(() {
            _allComplaints = complaints;
            _applyFilter(_selectedFilter);
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error fetching complaints: $e');
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;

      if (filter == 'All') {
        _filteredComplaints = List.from(_allComplaints);
      } else {
        ComplaintStatus status;
        switch (filter) {
          case 'Pending':
            status = ComplaintStatus.pending;
            break;
          case 'In Progress':
            status = ComplaintStatus.inProgress;
            break;
          case 'Resolved':
            status = ComplaintStatus.resolved;
            break;
          case 'Rejected':
            status = ComplaintStatus.rejected;
            break;
          default:
            status = ComplaintStatus.pending;
        }

        _filteredComplaints = _allComplaints.where((c) => c.status == status).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Complaint Management',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $_errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchComplaints,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Use a simpler layout structure to avoid rendering issues
    return SafeArea(
      child: Column(
        children: [
          // Header with filters only - simplified
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaints (${_filteredComplaints.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterSection(),
              ],
            ),
          ),

          // Complaint list
          Expanded(
            child: _filteredComplaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter Complaints',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchComplaints,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredComplaints.length,
                      itemBuilder: (context, index) {
                        try {
                          return _buildComplaintCard(_filteredComplaints[index]);
                        } catch (e) {
                          return const Card(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Error displaying complaint'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final pendingCount = _allComplaints.where((c) => c.status == ComplaintStatus.pending).length;
    final inProgressCount = _allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolvedCount = _allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final rejectedCount = _allComplaints.where((c) => c.status == ComplaintStatus.rejected).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complaint Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatCard('Pending', pendingCount, Colors.orange, Icons.hourglass_empty),
              _buildStatCard('In Progress', inProgressCount, Colors.blue, Icons.engineering),
              _buildStatCard('Resolved', resolvedCount, Colors.green, Icons.check_circle),
              _buildStatCard('Rejected', rejectedCount, Colors.red, Icons.cancel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyFilter(title),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          final color = _filterColors[filter] ?? AppColors.buttonColor;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _applyFilter(filter);
                }
              },
              backgroundColor: AppColors.lightBlack,
              selectedColor: color.withAlpha(50),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No $_selectedFilter Complaints',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'There are no complaints in the system yet'
                : 'There are no complaints with $_selectedFilter status',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    try {
      // Very basic card with minimal widgets to avoid layout issues
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.lightBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () async {
            try {
              if (complaint.status == ComplaintStatus.pending) {
                // For pending complaints, go to response page
                final result = await context.push(ComplaintResponsePage(complaint: complaint));
                if (result == true && mounted) {
                  _fetchComplaints();
                }
              } else {
                // For other complaints, show a dialog with details
                _showComplaintDetailsDialog(context, complaint);
              }
            } catch (e) {
              Utility.toast(message: 'Error navigating: $e');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  complaint.title ?? 'No title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(complaint.status).withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        complaint.statusDisplayName,
                        style: TextStyle(
                          color: _getStatusColor(complaint.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(complaint.createdAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  complaint.description ?? 'No description',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // User info - simplified
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint.userName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (complaint.imageUrl != null) const Icon(Icons.image, size: 16, color: Colors.green),
                  ],
                ),

                // Action button for pending complaints - simplified
                if (complaint.status == ComplaintStatus.pending) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final result = await context.push(ComplaintResponsePage(complaint: complaint));
                          if (result == true && mounted) {
                            _fetchComplaints();
                          }
                        } catch (e) {
                          Utility.toast(message: 'Error navigating: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Respond'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Super simple fallback card
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.red.withAlpha(50),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Error displaying complaint'),
        ),
      );
    }
  }

  // Helper methods to simplify the card
  Color _getStatusColor(ComplaintStatus? status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown date';
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

  void _showComplaintDetailsDialog(BuildContext context, ComplaintModel complaint) {
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

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.lightBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Complaint Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          complaint.statusDisplayName,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDialogInfoRow('Title', complaint.title ?? 'No title'),
                  const SizedBox(height: 8),
                  _buildDialogInfoRow('Description', complaint.description ?? 'No description', isMultiLine: true),
                  const SizedBox(height: 8),
                  _buildDialogInfoRow('Submitted by', complaint.userName ?? 'Unknown'),
                  const SizedBox(height: 8),
                  _buildDialogInfoRow('Villa', complaint.userVillaNumber ?? 'N/A'),
                  const SizedBox(height: 8),
                  _buildDialogInfoRow('Line', _formatLineNumber(complaint.userLineNumber)),
                  const SizedBox(height: 8),
                  _buildDialogInfoRow('Submitted on', formattedCreatedDate),
                  if (complaint.updatedAt != null && complaint.updatedAt != complaint.createdAt) ...[
                    const SizedBox(height: 8),
                    _buildDialogInfoRow('Last updated', formattedUpdatedDate),
                  ],

                  // Image preview if available
                  if (complaint.imageUrl != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Attached Image',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        complaint.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey.withAlpha(30),
                            child: const Center(
                              child: Text('Failed to load image'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  if (complaint.adminResponse != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Response',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint.adminResponse!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (complaint.status == ComplaintStatus.pending)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push(ComplaintResponsePage(complaint: complaint)).then((result) {
                              if (result == true && mounted) {
                                _fetchComplaints();
                              }
                            });
                          },
                          child: const Text('Respond'),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogInfoRow(String label, String value, {bool isMultiLine = false}) {
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
