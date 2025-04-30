import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/complaints/view/complaint_response_page.dart';
import 'package:society_management/complaints/view/simple_complaint_card.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> with SingleTickerProviderStateMixin {
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

  // Animation controller for statistics cards
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _fetchComplaints();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

          // Start animation after data is loaded
          _animationController.forward();
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
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchComplaints,
        child: _filteredComplaints.isEmpty
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatisticsSection(),
                        const SizedBox(height: 24),
                        _buildFilterSection(),
                        const SizedBox(height: 16),
                        Text(
                          'Complaints (${_filteredComplaints.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5, // Give enough space for the empty state
                    child: _buildEmptyState(),
                  ),
                ],
              )
            : Column(
                children: [
                  // Header section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatisticsSection(),
                        const SizedBox(height: 24),
                        _buildFilterSection(),
                        const SizedBox(height: 16),
                        Text(
                          'Complaints (${_filteredComplaints.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Complaint list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredComplaints.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        try {
                          final complaint = _filteredComplaints[index];
                          return SimpleComplaintCard(
                            complaint: complaint,
                            onRefresh: _fetchComplaints,
                            showDetailsDialog: _showComplaintDetailsDialog,
                          );
                        } catch (e) {
                          // Handle any errors in building individual cards
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.red.withAlpha(50),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error displaying complaint: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final pendingCount = _allComplaints.where((c) => c.status == ComplaintStatus.pending).length;
    final inProgressCount = _allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolvedCount = _allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final rejectedCount = _allComplaints.where((c) => c.status == ComplaintStatus.rejected).length;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complaint Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('Pending', pendingCount, Colors.orange, Icons.hourglass_empty),
              _buildStatCard('In Progress', inProgressCount, Colors.blue, Icons.engineering),
              _buildStatCard('Resolved', resolvedCount, Colors.green, Icons.check_circle),
              _buildStatCard('Rejected', rejectedCount, Colors.red, Icons.cancel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyFilter(title),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
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
        shrinkWrap: true,
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
    // Format date
    String formattedDate = 'Unknown date';
    if (complaint.createdAt != null) {
      try {
        final date = DateTime.parse(complaint.createdAt!);
        formattedDate = DateFormat('MMM d, yyyy').format(date);
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

    // Determine icon based on status
    IconData statusIcon;
    switch (complaint.status) {
      case ComplaintStatus.pending:
        statusIcon = Icons.hourglass_empty;
        break;
      case ComplaintStatus.inProgress:
        statusIcon = Icons.engineering;
        break;
      case ComplaintStatus.resolved:
        statusIcon = Icons.check_circle;
        break;
      case ComplaintStatus.rejected:
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.lightBlack,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withAlpha(50)),
      ),
      child: InkWell(
        onTap: () async {
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
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
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

                  // User info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.buttonColor.withAlpha(50),
                        radius: 16,
                        child: Text(
                          complaint.userName?.isNotEmpty == true ? complaint.userName![0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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

                      // Image indicator
                      if (complaint.imageUrl != null)
                        Tooltip(
                          message: 'Has image attachment',
                          child: Container(
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
                        ),
                    ],
                  ),

                  // Admin response preview
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

                  // Action button for pending complaints
                  if (complaint.status == ComplaintStatus.pending) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await context.push(ComplaintResponsePage(complaint: complaint));
                            if (result == true && mounted) {
                              _fetchComplaints();
                            }
                          },
                          icon: const Icon(Icons.reply, size: 16),
                          label: const Text('Respond'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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

    // Determine icon based on status
    IconData statusIcon;
    switch (complaint.status) {
      case ComplaintStatus.pending:
        statusIcon = Icons.hourglass_empty;
        break;
      case ComplaintStatus.inProgress:
        statusIcon = Icons.engineering;
        break;
      case ComplaintStatus.resolved:
        statusIcon = Icons.check_circle;
        break;
      case ComplaintStatus.rejected:
        statusIcon = Icons.cancel;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Complaint Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
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
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogInfoRow('Title', complaint.title ?? 'No title'),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow('Description', complaint.description ?? 'No description', isMultiLine: true),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow('Submitted by', complaint.userName ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow('Villa', complaint.userVillaNumber ?? 'N/A'),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow('Line', _formatLineNumber(complaint.userLineNumber)),
                      const SizedBox(height: 12),
                      _buildDialogInfoRow('Submitted on', formattedCreatedDate),

                      if (complaint.updatedAt != null && complaint.updatedAt != complaint.createdAt) ...[
                        const SizedBox(height: 12),
                        _buildDialogInfoRow('Last updated', formattedUpdatedDate),
                      ],

                      // Image preview if available
                      if (complaint.imageUrl != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Attached Image',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                        ),
                        const SizedBox(height: 12),
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

                      // Admin response
                      if (complaint.adminResponse != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Admin Response',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withAlpha(50)),
                          ),
                          child: Text(
                            complaint.adminResponse!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],

                      // Action buttons
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (complaint.status == ComplaintStatus.pending)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push(ComplaintResponsePage(complaint: complaint)).then((result) {
                                  if (result == true && mounted) {
                                    _fetchComplaints();
                                  }
                                });
                              },
                              icon: const Icon(Icons.reply),
                              label: const Text('Respond'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.buttonColor,
                              ),
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
