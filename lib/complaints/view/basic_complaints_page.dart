import 'package:flutter/material.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/complaints/view/complaint_response_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class BasicComplaintsPage extends StatefulWidget {
  const BasicComplaintsPage({super.key});

  @override
  State<BasicComplaintsPage> createState() => _BasicComplaintsPageState();
}

class _BasicComplaintsPageState extends State<BasicComplaintsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ComplaintModel> _complaints = [];

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
        title: 'Complaints',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildBasicList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            ElevatedButton(
              onPressed: _fetchComplaints,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicList() {
    if (_complaints.isEmpty) {
      return const Center(
        child: Text('No complaints found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        try {
          final complaint = _complaints[index];
          return _buildBasicCard(complaint);
        } catch (e) {
          return const Card(
            margin: EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Error displaying complaint'),
            ),
          );
        }
      },
    );
  }

  Widget _buildBasicCard(ComplaintModel complaint) {
    // Super simple card with minimal widgets
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          complaint.title ?? 'No title',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          complaint.description ?? 'No description',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _getStatusIndicator(complaint.status),
        onTap: () {
          _handleComplaintTap(complaint);
        },
      ),
    );
  }

  Widget _getStatusIndicator(ComplaintStatus? status) {
    Color color;
    switch (status) {
      case ComplaintStatus.pending:
        color = Colors.orange;
        break;
      case ComplaintStatus.inProgress:
        color = Colors.blue;
        break;
      case ComplaintStatus.resolved:
        color = Colors.green;
        break;
      case ComplaintStatus.rejected:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _handleComplaintTap(ComplaintModel complaint) {
    try {
      if (complaint.status == ComplaintStatus.pending) {
        context.push(ComplaintResponsePage(complaint: complaint)).then((result) {
          if (result == true) {
            _fetchComplaints();
          }
        });
      } else {
        _showBasicDetailsDialog(context, complaint);
      }
    } catch (e) {
      Utility.toast(message: 'Error: $e');
    }
  }

  void _showBasicDetailsDialog(BuildContext context, ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(complaint.title ?? 'Complaint Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status: ${complaint.statusDisplayName}'),
                const SizedBox(height: 8),
                Text('Description: ${complaint.description ?? 'No description'}'),
                const SizedBox(height: 8),
                Text('Submitted by: ${complaint.userName ?? 'Unknown'}'),
                if (complaint.adminResponse != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Admin Response:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(complaint.adminResponse!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
