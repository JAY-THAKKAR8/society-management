import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:uuid/uuid.dart';

class ExpenseItemList extends StatefulWidget {
  const ExpenseItemList({
    super.key,
    required this.items,
    required this.onItemsChanged,
  });

  final List<ExpenseItemModel> items;
  final Function(List<ExpenseItemModel> items) onItemsChanged;

  @override
  State<ExpenseItemList> createState() => _ExpenseItemListState();
}

class _ExpenseItemListState extends State<ExpenseItemList> {
  late List<ExpenseItemModel> _items;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      setState(() {
        _items.add(ExpenseItemModel(
          id: const Uuid().v4(),
          name: name,
          price: price,
        ));
      });

      widget.onItemsChanged(_items);
      _nameController.clear();
      _priceController.clear();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onItemsChanged(_items);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Items',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Gap(16),
        Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: AppTextFormField(
                  controller: _nameController,
                  hintText: 'Item Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
              ),
              const Gap(8),
              Expanded(
                child: AppTextFormField(
                  controller: _priceController,
                  hintText: 'Price',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                ),
              ),
              const Gap(8),
              IconButton(
                onPressed: _addItem,
                icon: const Icon(Icons.add_circle, color: AppColors.buttonColor),
              ),
            ],
          ),
        ),
        const Gap(16),
        if (_items.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Item Name',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Price',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Use Column instead of ListView to avoid nested scrolling issues
                Column(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    return Column(
                      children: [
                        if (index > 0) const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(item.name ?? ''),
                              ),
                              Expanded(
                                child: Text('₹${item.price?.toStringAsFixed(2) ?? '0.00'}'),
                              ),
                              IconButton(
                                onPressed: () => _removeItem(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: ₹${_calculateTotal().toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  double _calculateTotal() {
    return _items.fold(0, (sum, item) => sum + (item.price ?? 0));
  }
}
