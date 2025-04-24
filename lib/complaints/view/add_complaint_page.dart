import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';

class AddComplaintPage extends StatefulWidget {
  const AddComplaintPage({super.key});

  @override
  State<AddComplaintPage> createState() => _AddComplaintPageState();
}

class _AddComplaintPageState extends State<AddComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isLoading = ValueNotifier<bool>(false);
  UserModel? _currentUser;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await AuthService().getCurrentUser();
      setState(() {
        _currentUser = user;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      Utility.toast(message: 'Error getting user data: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        Utility.toast(message: 'User data not available. Please try again.');
        return;
      }

      _isLoading.value = true;

      try {
        final complaintRepository = getIt<IComplaintRepository>();
        final result = await complaintRepository.addComplaint(
          userId: _currentUser!.id!,
          userName: _currentUser!.name ?? 'Unknown',
          userVillaNumber: _currentUser!.villNumber,
          userLineNumber: _currentUser!.lineNumber,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        result.fold(
          (failure) {
            _isLoading.value = false;
            Utility.toast(message: failure.message);
          },
          (_) {
            _isLoading.value = false;
            Utility.toast(message: 'Complaint submitted successfully');
            context.pop();
          },
        );
      } catch (e) {
        _isLoading.value = false;
        Utility.toast(message: 'Error submitting complaint: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Submit Complaint',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoCard(),
                    const Gap(20),
                    AppTextFormField(
                      controller: _titleController,
                      title: 'Complaint Title*',
                      hintText: 'Enter a brief title for your complaint',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                      ],
                    ),
                    const Gap(20),
                    AppTextFormField(
                      controller: _descriptionController,
                      title: 'Description*',
                      hintText: 'Describe your complaint in detail',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1000),
                      ],
                    ),
                    const Gap(30),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isLoading,
                      builder: (context, loading, _) {
                        return CommonButton(
                          isLoading: loading,
                          text: 'Submit Complaint',
                          onTap: _submitComplaint,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(12),
            _buildInfoRow('Name', _currentUser?.name ?? 'Not available'),
            if (_currentUser?.villNumber != null)
              _buildInfoRow('Villa Number', _currentUser!.villNumber!),
            _buildInfoRow('Line', _currentUser?.userLineViewString ?? 'Not assigned'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
