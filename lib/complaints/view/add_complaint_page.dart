import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/constants/app_colors.dart';
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
  final _imagePicker = ImagePicker();
  UserModel? _currentUser;
  bool _isInitializing = true;
  File? _selectedImage;
  String? _imageUrl;

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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Utility.toast(message: 'Error picking image: $e');
    }
  }

  Future<void> _takeScreenshot() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Utility.toast(message: 'Error taking screenshot: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrl = null;
    });
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || _currentUser == null) return;

    try {
      final complaintRepository = getIt<IComplaintRepository>();
      final result = await complaintRepository.uploadComplaintImage(
        _currentUser!.id!,
        _selectedImage!.path,
      );

      result.fold(
        (failure) {
          Utility.toast(message: 'Failed to upload image: ${failure.message}');
        },
        (url) {
          _imageUrl = url;
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error uploading image: $e');
    }
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        Utility.toast(message: 'User data not available. Please try again.');
        return;
      }

      _isLoading.value = true;

      try {
        // Upload image if selected
        if (_selectedImage != null) {
          await _uploadImage();
        }

        final complaintRepository = getIt<IComplaintRepository>();
        final result = await complaintRepository.addComplaint(
          userId: _currentUser!.id!,
          userName: _currentUser!.name ?? 'Unknown',
          userVillaNumber: _currentUser!.villNumber,
          userLineNumber: _currentUser!.lineNumber,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrl,
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
                    const Gap(20),
                    _buildImageSection(),
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
            if (_currentUser?.villNumber != null) _buildInfoRow('Villa Number', _currentUser!.villNumber!),
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Screenshot (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Gap(12),
        if (_selectedImage != null) ...[
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(100)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImagePickerButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickImage,
              ),
              _buildImagePickerButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: _takeScreenshot,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(100)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.buttonColor,
            ),
            const Gap(8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.buttonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
