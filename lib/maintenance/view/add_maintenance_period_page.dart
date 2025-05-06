import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';

class AddMaintenancePeriodPage extends StatefulWidget {
  final String? periodId;

  const AddMaintenancePeriodPage({super.key, this.periodId});

  @override
  State<AddMaintenancePeriodPage> createState() => _AddMaintenancePeriodPageState();
}

class _AddMaintenancePeriodPageState extends State<AddMaintenancePeriodPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  UserModel? _currentUser;
  bool _isAdmin = false;

  // First day of current month as default start date
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  // Last day of current month as default end date
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  // Default due date is the 10th of the month
  DateTime dueDate = DateTime(DateTime.now().year, DateTime.now().month, 10);

  final isLoading = ValueNotifier<bool>(false);
  final isButtonLoading = ValueNotifier<bool>(false);
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    _checkUserAccess();
    if (widget.periodId != null) {
      _fetchPeriodDetails();
    }
  }

  Future<void> _checkUserAccess() async {
    try {
      final userRepository = getIt<IUserRepository>();
      final userResult = await userRepository.getCurrentUser();

      userResult.fold(
        (failure) {
          // If we can't get the user, assume they're not an admin and redirect
          Utility.toast(message: 'Access denied: Only admins can manage maintenance periods');
          if (mounted) {
            context.pop();
          }
        },
        (user) {
          setState(() {
            _currentUser = user;
            // Fix admin role check to be more inclusive
            _isAdmin = user.role == AppConstants.admin || // 'ADMIN'
                user.role == AppConstants.admins || // 'Admin'
                user.role?.toLowerCase() == 'admin';

            // Debug message
            Utility.toast(message: 'User role: ${user.role}, Is admin: $_isAdmin');
          });

          // If not an admin, redirect back
          if (!_isAdmin && mounted) {
            Utility.toast(message: 'Access denied: Only admins can manage maintenance periods');
            context.pop();
          }
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error checking user access: $e');
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _fetchPeriodDetails() async {
    isLoading.value = true;
    final response = await getIt<IMaintenanceRepository>().getMaintenancePeriod(
      periodId: widget.periodId!,
    );

    response.fold(
      (failure) {
        isLoading.value = false;
        Utility.toast(message: failure.message);
      },
      (period) {
        nameController.text = period.name ?? '';
        descriptionController.text = period.description ?? '';
        amountController.text = period.amount?.toString() ?? '';

        if (period.startDate != null) {
          startDate = DateTime.parse(period.startDate!);
        }

        if (period.endDate != null) {
          endDate = DateTime.parse(period.endDate!);
        }

        if (period.dueDate != null) {
          dueDate = DateTime.parse(period.dueDate!);
        }

        isActive = period.isActive;
        isLoading.value = false;
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.periodId == null ? 'Add Maintenance Period' : 'Edit Maintenance Period',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: isLoading,
        builder: (context, loading, _) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextFormField(
                    controller: nameController,
                    title: 'Period Name*',
                    hintText: 'e.g. April 2023 Maintenance',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter period name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Typically the month and year for which maintenance is being collected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Gap(20),
                  AppTextFormField(
                    controller: descriptionController,
                    title: 'Description',
                    hintText: 'Optional description',
                    maxLines: 3,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(500),
                    ],
                  ),
                  const Gap(20),
                  AppTextFormField(
                    controller: amountController,
                    title: 'Amount per Member (₹)*',
                    hintText: 'e.g. 1000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      try {
                        final amount = double.parse(value);
                        if (amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),
                  _buildDatePicker(
                    context,
                    'Start Date (Month Beginning)*',
                    startDate,
                    (date) {
                      setState(() {
                        // Set to first day of selected month
                        startDate = DateTime(date.year, date.month, 1);

                        // Set end date to last day of the same month
                        endDate = DateTime(date.year, date.month + 1, 0);

                        // Set due date to 10th of the month by default
                        // or keep it if it's already within the month
                        if (dueDate.month != startDate.month || dueDate.year != startDate.year) {
                          dueDate = DateTime(date.year, date.month, 10);
                        } else if (dueDate.isAfter(endDate)) {
                          dueDate = endDate;
                        }
                      });
                    },
                    helpText: 'This is typically the first day of the month',
                  ),
                  const Gap(20),
                  _buildDatePicker(
                    context,
                    'Due Date (Payment Deadline)*',
                    dueDate,
                    (date) {
                      setState(() {
                        dueDate = date;
                      });
                    },
                    firstDate: startDate,
                    lastDate: endDate,
                    helpText: 'Last date for members to pay maintenance fees',
                  ),
                  const Gap(20),
                  _buildDatePicker(
                    context,
                    'End Date (Month End)*',
                    endDate,
                    (date) {
                      setState(() {
                        // Set to last day of selected month
                        endDate = DateTime(date.year, date.month + 1, 0);

                        // Ensure due date is not after end date
                        if (dueDate.isAfter(endDate)) {
                          dueDate = endDate;
                        }
                      });
                    },
                    firstDate: startDate,
                    helpText: 'This is typically the last day of the month',
                  ),
                  if (widget.periodId != null) ...[
                    const Gap(20),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Toggle to activate or deactivate this period'),
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
                      activeColor: AppColors.buttonColor,
                    ),
                  ],
                  const Gap(30),
                  ValueListenableBuilder<bool>(
                    valueListenable: isButtonLoading,
                    builder: (context, loading, _) {
                      return CommonButton(
                        isLoading: loading,
                        text: widget.periodId == null ? 'Create Period' : 'Update Period',
                        onTap: _submitForm,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime selectedDate,
    Function(DateTime) onDateChanged, {
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
              lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
              helpText: helpText,
            );
            if (pickedDate != null) {
              onDateChanged(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      isButtonLoading.value = true;

      try {
        final maintenanceRepository = getIt<IMaintenanceRepository>();
        final amount = double.parse(amountController.text.trim());

        if (widget.periodId == null) {
          // Create new period
          final result = await maintenanceRepository.createMaintenancePeriod(
            name: nameController.text.trim(),
            description: descriptionController.text.trim(),
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            dueDate: dueDate,
          );

          result.fold(
            (failure) {
              isButtonLoading.value = false;
              Utility.toast(message: failure.message);
            },
            (_) {
              isButtonLoading.value = false;
              Utility.toast(message: 'Maintenance period created successfully');
              context.pop();
            },
          );
        } else {
          // Update existing period
          final result = await maintenanceRepository.updateMaintenancePeriod(
            periodId: widget.periodId!,
            name: nameController.text.trim(),
            description: descriptionController.text.trim(),
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            dueDate: dueDate,
            isActive: isActive,
          );

          result.fold(
            (failure) {
              isButtonLoading.value = false;
              Utility.toast(message: failure.message);
            },
            (_) {
              isButtonLoading.value = false;
              Utility.toast(message: 'Maintenance period updated successfully');
              context.pop();
            },
          );
        }
      } catch (e) {
        isButtonLoading.value = false;
        Utility.toast(message: 'Error: $e');
      }
    }
  }
}
