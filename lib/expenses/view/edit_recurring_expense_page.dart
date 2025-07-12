import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/expenses/model/recurring_expense_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class EditRecurringExpensePage extends StatefulWidget {
  final RecurringExpenseModel expense;
  final Function(RecurringExpenseModel updatedExpense) onExpenseUpdated;

  const EditRecurringExpensePage({
    super.key,
    required this.expense,
    required this.onExpenseUpdated,
  });

  @override
  State<EditRecurringExpensePage> createState() => _EditRecurringExpensePageState();
}

class _EditRecurringExpensePageState extends State<EditRecurringExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final _contactController = TextEditingController();
  
  late RecurringExpenseType _selectedType;
  late RecurringFrequency _selectedFrequency;
  late int _selectedDueDate;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController.text = widget.expense.name;
    _amountController.text = widget.expense.amount.toString();
    _descriptionController.text = widget.expense.description ?? '';
    _vendorNameController.text = widget.expense.vendorName ?? '';
    _contactController.text = widget.expense.contactNumber ?? '';
    
    _selectedType = widget.expense.type;
    _selectedFrequency = widget.expense.frequency;
    _selectedDueDate = widget.expense.dueDate ?? 1;
    _isActive = widget.expense.isActive;
  }

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
        title: '✏️ Edit Recurring Expense',
        showDivider: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateExpense,
            child: Text(
              'Update',
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
              _buildStatusSection(isDark),
              const Gap(20),
              _buildActionButtons(isDark),
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
            AppColors.primaryOrange.withValues(alpha: 0.8),
            AppColors.primaryBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.expense.type.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Recurring Expense',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.expense.name,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(16),
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
                        color: isSelected 
                            ? AppColors.primaryBlue 
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
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
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 16),
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
        padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(16),
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

  Widget _buildStatusSection(bool isDark) {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: Text(
                _isActive 
                    ? 'This expense is currently active and will be tracked'
                    : 'This expense is inactive and will not be tracked',
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _showDeleteConfirmation,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                : const Text('Update Expense'),
          ),
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Call service to update expense
      await Future.delayed(const Duration(seconds: 1));
      
      // Create updated expense model
      final updatedExpense = widget.expense.copyWith(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        type: _selectedType,
        frequency: _selectedFrequency,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        vendorName: _vendorNameController.text.trim().isEmpty 
            ? null 
            : _vendorNameController.text.trim(),
        contactNumber: _contactController.text.trim().isEmpty 
            ? null 
            : _contactController.text.trim(),
        dueDate: _selectedDueDate,
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );

      widget.onExpenseUpdated(updatedExpense);
      
      Utility.toast(message: 'Expense updated successfully!');
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      Utility.toast(message: 'Error updating expense: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${widget.expense.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteExpense();
    }
  }

  Future<void> _deleteExpense() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Call service to delete expense
      await Future.delayed(const Duration(seconds: 1));
      
      Utility.toast(message: 'Expense deleted successfully!');
      if (mounted) {
        context.pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      Utility.toast(message: 'Error deleting expense: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
