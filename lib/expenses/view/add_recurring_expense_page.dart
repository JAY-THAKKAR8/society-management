import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/expenses/model/recurring_expense_model.dart';
import 'package:society_management/expenses/service/expense_service.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class AddRecurringExpensePage extends StatefulWidget {
  const AddRecurringExpensePage({super.key});

  @override
  State<AddRecurringExpensePage> createState() => _AddRecurringExpensePageState();
}

class _AddRecurringExpensePageState extends State<AddRecurringExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final _contactController = TextEditingController();

  RecurringExpenseType _selectedType = RecurringExpenseType.security;
  RecurringFrequency _selectedFrequency = RecurringFrequency.monthly;
  int _selectedDueDate = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorNameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: CommonAppBar(
        title: '➕ Add Monthly Fixed Expense',
        showDivider: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(isDark),
              const Gap(20),
              _buildBasicInfoSection(isDark),
              const Gap(20),
              _buildTypeSelectionSection(isDark),
              const Gap(20),
              _buildScheduleSection(isDark),
              const Gap(20),
              _buildVendorInfoSection(isDark),
              const Gap(20),
              _buildSaveButton(isDark),
              const Gap(100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.8),
            AppColors.primaryBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
              Gap(12),
              Text(
                'New Recurring Expense',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Gap(8),
          Text(
            'Set up automatic tracking for monthly expenses like security, utilities, and maintenance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Expense Name *',
                hintText: 'e.g., Security Guard Salary',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter expense name';
                }
                return null;
              },
            ),
            const Gap(16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                hintText: 'Enter amount in ₹',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter valid amount';
                }
                return null;
              },
            ),
            const Gap(16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Additional details about this expense',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelectionSection(bool isDark) {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3,
              ),
              itemCount: RecurringExpenseType.values.length,
              itemBuilder: (context, index) {
                final type = RecurringExpenseType.values[index];
                final isSelected = _selectedType == type;

                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : (isDark ? Colors.grey[800] : Colors.grey[50]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(type.emoji, style: const TextStyle(fontSize: 20)),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primaryBlue : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(bool isDark) {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            DropdownButtonFormField<RecurringFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                prefixIcon: Icon(Icons.repeat),
                border: OutlineInputBorder(),
              ),
              items: RecurringFrequency.values.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(frequency.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFrequency = value);
                }
              },
            ),
            const Gap(16),
            DropdownButtonFormField<int>(
              value: _selectedDueDate,
              decoration: const InputDecoration(
                labelText: 'Due Date (Day of Month)',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              items: List.generate(31, (index) => index + 1).map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text('$day${_getOrdinalSuffix(day)} of every month'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDueDate = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfoSection(bool isDark) {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor Information (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            TextFormField(
              controller: _vendorNameController,
              decoration: const InputDecoration(
                labelText: 'Vendor/Service Provider Name',
                hintText: 'e.g., Ramesh Kumar, MSEB',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                hintText: '+91 9876543210',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Recurring Expense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create monthly fixed expense using service
      final savedExpense = await RecurringExpenseService.instance.createMonthlyFixedExpense(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        vendorName: _vendorNameController.text.trim().isEmpty ? null : _vendorNameController.text.trim(),
        contactNumber: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        dueDate: _selectedDueDate,
        createdBy: 'Admin', // TODO: Get from auth service
      );

      if (savedExpense == null) {
        throw Exception('Failed to save expense to database');
      }

      Utility.toast(message: 'Recurring expense saved successfully!');
      if (mounted) {
        // Return the saved expense to the previous page
        context.pop(savedExpense);
      }
    } catch (e) {
      Utility.toast(message: 'Error saving expense: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
