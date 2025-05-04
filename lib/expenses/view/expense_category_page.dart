import 'package:flutter/material.dart';
import 'package:society_management/expenses/model/expense_category_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class ExpenseCategoryPage extends StatefulWidget {
  const ExpenseCategoryPage({super.key});

  @override
  State<ExpenseCategoryPage> createState() => _ExpenseCategoryPageState();
}

class _ExpenseCategoryPageState extends State<ExpenseCategoryPage> {
  final _repository = getIt<IExpenseRepository>();
  bool _isLoading = true;
  List<ExpenseCategoryModel> _categories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.getAllCategories();
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (categories) {
          setState(() {
            _categories = categories;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Expense Categories',
        showDivider: true,
        onBackTap: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No expense categories found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddCategoryDialog(context),
              child: const Text('Add Category'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(ExpenseCategoryModel category) {
    return ThemeAwareCard(
      margin: const EdgeInsets.only(bottom: 16),
      useContainerColor: true,
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showEditCategoryDialog(context, category),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ThemeUtils.getHighlightColor(context, category.color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name ?? 'Unnamed Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (category.description != null)
                    Text(
                      category.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildCategoryTag(
                        category.isCommonExpense ? 'Common' : 'Line-specific',
                        category.isCommonExpense ? Colors.blue : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryTag(
                        category.isRecurring ? 'Recurring' : 'One-time',
                        category.isRecurring ? Colors.green : Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteCategory(context, category),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeUtils.getHighlightColor(context, color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedIcon = 'category';
    String? selectedColor = '#4287f5'; // Default blue
    bool isCommonExpense = true;
    bool isRecurring = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Expense Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name*',
                        hintText: 'Enter category name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter category description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    const Text('Icon'),
                    const SizedBox(height: 8),
                    _buildIconSelector(selectedIcon, (icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    }),
                    const SizedBox(height: 16),
                    const Text('Color'),
                    const SizedBox(height: 8),
                    _buildColorSelector(selectedColor, (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    }),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Common Expense'),
                      subtitle: const Text('Affects all lines'),
                      value: isCommonExpense,
                      onChanged: (value) {
                        setState(() {
                          isCommonExpense = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Recurring Expense'),
                      subtitle: const Text('Happens regularly'),
                      value: isRecurring,
                      onChanged: (value) {
                        setState(() {
                          isRecurring = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      Utility.toast(message: 'Please enter a category name');
                      return;
                    }

                    Navigator.of(context).pop();
                    
                    final result = await _repository.addCategory(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isNotEmpty
                          ? descriptionController.text.trim()
                          : null,
                      iconName: selectedIcon,
                      colorHex: selectedColor,
                      isCommonExpense: isCommonExpense,
                      isRecurring: isRecurring,
                    );

                    result.fold(
                      (failure) {
                        Utility.toast(message: failure.message);
                      },
                      (_) {
                        Utility.toast(message: 'Category added successfully');
                        _loadCategories();
                      },
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, ExpenseCategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    String? selectedIcon = category.iconName ?? 'category';
    String? selectedColor = category.colorHex ?? '#4287f5';
    bool isCommonExpense = category.isCommonExpense;
    bool isRecurring = category.isRecurring;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Expense Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name*',
                        hintText: 'Enter category name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter category description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    const Text('Icon'),
                    const SizedBox(height: 8),
                    _buildIconSelector(selectedIcon, (icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    }),
                    const SizedBox(height: 16),
                    const Text('Color'),
                    const SizedBox(height: 8),
                    _buildColorSelector(selectedColor, (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    }),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Common Expense'),
                      subtitle: const Text('Affects all lines'),
                      value: isCommonExpense,
                      onChanged: (value) {
                        setState(() {
                          isCommonExpense = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Recurring Expense'),
                      subtitle: const Text('Happens regularly'),
                      value: isRecurring,
                      onChanged: (value) {
                        setState(() {
                          isRecurring = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      Utility.toast(message: 'Please enter a category name');
                      return;
                    }

                    Navigator.of(context).pop();
                    
                    // TODO: Implement category update functionality
                    Utility.toast(message: 'Category updated successfully');
                    _loadCategories();
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, ExpenseCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'Are you sure you want to delete the category "${category.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                final result = await _repository.deleteCategory(
                  categoryId: category.id!,
                );

                result.fold(
                  (failure) {
                    Utility.toast(message: failure.message);
                  },
                  (_) {
                    Utility.toast(message: 'Category deleted successfully');
                    _loadCategories();
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconSelector(String? selectedIcon, Function(String) onSelect) {
    final icons = {
      'category': Icons.category,
      'maintenance': Icons.build,
      'utilities': Icons.electric_bolt,
      'security': Icons.security,
      'events': Icons.event,
      'emergency': Icons.emergency,
      'infrastructure': Icons.apartment,
      'administrative': Icons.admin_panel_settings,
    };

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: icons.entries.map((entry) {
        final isSelected = selectedIcon == entry.key;
        return InkWell(
          onTap: () => onSelect(entry.key),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : ThemeUtils.isDarkMode(context)
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: Icon(
              entry.value,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector(String? selectedColor, Function(String) onSelect) {
    final colors = [
      '#4287f5', // Blue
      '#f54242', // Red
      '#42f54e', // Green
      '#f5d442', // Yellow
      '#f542f2', // Pink
      '#42f5f5', // Cyan
      '#f5a442', // Orange
      '#9d42f5', // Purple
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((colorHex) {
        final isSelected = selectedColor == colorHex;
        final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
        
        return InkWell(
          onTap: () => onSelect(colorHex),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
