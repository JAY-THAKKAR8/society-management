import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';
import 'package:society_management/expenses/widgets/expense_item_list.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_button.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  final Function({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<ExpenseItemModel> items,
    String? description,
  }) onSubmit;
  final bool isLoading;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  final List<ExpenseItemModel> _items = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await Utility.datePicker(
      context: context,
      initialDate: _startDate,
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        _startDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await Utility.datePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
    );

    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
        _endDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one expense item')),
        );
        return;
      }

      widget.onSubmit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        startDate: _startDate!,
        endDate: _endDate!,
        items: _items,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextFormField(
            controller: _nameController,
            title: 'Expense Name*',
            hintText: 'Enter expense name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter expense name';
              }
              return null;
            },
          ),
          const Gap(20),
          AppTextFormField(
            controller: _descriptionController,
            title: 'Description',
            hintText: 'Enter expense description (optional)',
            maxLines: 3,
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: AppTextFormField(
                  controller: _startDateController,
                  title: 'Start Date*',
                  hintText: 'Select start date',
                  readOnly: true,
                  onTap: _selectStartDate,
                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select start date';
                    }
                    return null;
                  },
                ),
              ),
              const Gap(16),
              Expanded(
                child: AppTextFormField(
                  controller: _endDateController,
                  title: 'End Date*',
                  hintText: 'Select end date',
                  readOnly: true,
                  onTap: _selectEndDate,
                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select end date';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const Gap(24),
          ExpenseItemList(
            items: _items,
            onItemsChanged: (items) {
              setState(() {
                _items.clear();
                _items.addAll(items);
              });
            },
          ),
          const Gap(32),
          CommonButton(
            text: 'Submit',
            isLoading: widget.isLoading,
            onTap: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
