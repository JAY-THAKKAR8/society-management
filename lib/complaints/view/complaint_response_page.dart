import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class ComplaintResponsePage extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintResponsePage({
    super.key,
    required this.complaint,
  });

  @override
  State<ComplaintResponsePage> createState() => _ComplaintResponsePageState();
}

class _ComplaintResponsePageState extends State<ComplaintResponsePage> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  bool _isInProgress = false;
  ComplaintStatus _selectedStatus = ComplaintStatus.inProgress;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isInProgress = true;
    });

    try {
      final complaintRepository = getIt<IComplaintRepository>();

      // Create updated complaint with admin response
      final updatedComplaint = widget.complaint.copyWith(
        status: _selectedStatus,
        adminResponse: _responseController.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final result = await complaintRepository.updateComplaint(updatedComplaint);

      result.fold(
        (failure) {
          setState(() {
            _isInProgress = false;
          });
          Utility.toast(message: failure.message);
        },
        (_) {
          setState(() {
            _isInProgress = false;
          });
          Utility.toast(message: 'Response submitted successfully');
          context.pop(true); // Return true to indicate success
        },
      );
    } catch (e) {
      setState(() {
        _isInProgress = false;
      });
      Utility.toast(message: 'Error submitting response: $e');
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

  @override
  Widget build(BuildContext context) {
    // Format date
    String formattedDate = 'Unknown date';
    if (widget.complaint.createdAt != null) {
      try {
        final date = DateTime.parse(widget.complaint.createdAt!);
        formattedDate = DateFormat('MMM d, yyyy, h:mm a').format(date);
      } catch (e) {
        // Use default value
      }
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Respond to Complaint',
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
            _buildComplaintDetailsCard(formattedDate),
            const SizedBox(height: 24),
            _buildResponseForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintDetailsCard(String formattedDate) {
    return ThemeAwareCard(
      useContainerColor: true,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complaint Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Title', widget.complaint.title ?? 'No title'),
            const SizedBox(height: 8),
            _buildInfoRow('Description', widget.complaint.description ?? 'No description', isMultiLine: true),
            const SizedBox(height: 8),
            _buildInfoRow('Submitted by', widget.complaint.userName ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow('Villa', widget.complaint.userVillaNumber ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Line', _formatLineNumber(widget.complaint.userLineNumber)),
            const SizedBox(height: 8),
            _buildInfoRow('Submitted on', formattedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiLine = false}) {
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

  Widget _buildResponseForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Response',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildStatusSelector(),
          const SizedBox(height: 16),
          AppTextFormField(
            controller: _responseController,
            title: 'Response Message*',
            hintText: 'Enter your response to this complaint',
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a response';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CommonButton(
            onTap: _isInProgress ? null : _submitResponse,
            text: _isInProgress ? 'Submitting...' : 'Submit Response',
            isLoading: _isInProgress,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeUtils.getContainerColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildStatusOption(
            title: 'In Progress',
            subtitle: 'The complaint is being addressed',
            value: ComplaintStatus.inProgress,
            color: Colors.blue,
          ),
          const Divider(),
          _buildStatusOption(
            title: 'Resolved',
            subtitle: 'The complaint has been resolved',
            value: ComplaintStatus.resolved,
            color: Colors.green,
          ),
          const Divider(),
          _buildStatusOption(
            title: 'Rejected',
            subtitle: 'The complaint has been rejected',
            value: ComplaintStatus.rejected,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required ComplaintStatus value,
    required Color color,
  }) {
    return RadioListTile<ComplaintStatus>(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      subtitle: Text(subtitle),
      value: value,
      groupValue: _selectedStatus,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedStatus = newValue;
          });
        }
      },
      activeColor: color,
      contentPadding: EdgeInsets.zero,
    );
  }
}
