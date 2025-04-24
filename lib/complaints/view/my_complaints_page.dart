import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/complaints/view/add_complaint_page.dart';
import 'package:society_management/complaints/view/complaint_detail_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ComplaintModel> _complaints = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUserAndComplaints();
  }

  Future<void> _getCurrentUserAndComplaints() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User data not available';
        });
        return;
      }

      _currentUser = user;

      // Get complaints for this user
      final complaintRepository = getIt<IComplaintRepository>();
      final result = await complaintRepository.getComplaintsForUser(
        userId: user.id!,
      );

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
            _complaints = complaints;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'My Complaints',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(const AddComplaintPage());
          // Refresh complaints when returning
          if (mounted) {
            _getCurrentUserAndComplaints();
          }
        },
        backgroundColor: AppColors.buttonColor,
        child: const Icon(Icons.add),
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
                        onPressed: _getCurrentUserAndComplaints,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _complaints.isEmpty
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
                          const Text(
                            'No complaints yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to submit a new complaint',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              context.push(const AddComplaintPage());
                            },
                            child: const Text('Add Complaint'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _getCurrentUserAndComplaints,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          return _buildComplaintCard(_complaints[index]);
                        },
                      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: InkWell(
        onTap: () {
          context.push(ComplaintDetailPage(complaint: complaint));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.title ?? 'No title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
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
              const SizedBox(height: 8),
              Text(
                complaint.description ?? 'No description',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  if (complaint.adminResponse != null)
                    const Icon(
                      Icons.comment,
                      size: 16,
                      color: Colors.blue,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
