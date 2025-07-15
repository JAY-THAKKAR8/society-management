import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';
import 'package:society_management/expenses/model/expense_model.dart';
import 'package:society_management/expenses/repository/i_expense_repository.dart';
import 'package:society_management/expenses/view/add_expense_page.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class ExpenseDetailsPage extends StatefulWidget {
  final String expenseId;
  final ExpenseModel? expense; // Optional - if already have expense data

  const ExpenseDetailsPage({
    super.key,
    required this.expenseId,
    this.expense,
  });

  @override
  State<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  final _repository = getIt<IExpenseRepository>();
  ExpenseModel? _expense;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _expense = widget.expense;
      _isLoading = false;
    } else {
      _loadExpenseDetails();
    }
  }

  Future<void> _loadExpenseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getExpense(expenseId: widget.expenseId);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
        Utility.toast(message: 'Error loading expense: ${failure.message}');
      },
      (expense) {
        setState(() {
          _expense = expense;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Expense Details',
        showDivider: true,
        onBackTap: () => context.pop(),
        actions: [
          if (_expense != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to AddExpensePage in edit mode
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => AddExpensePage(
                      expenseToEdit: _expense!,
                    ),
                  ),
                )
                    .then((result) {
                  // Refresh the expense details if edited
                  if (result == true) {
                    _loadExpenseDetails();
                    Utility.toast(message: 'Expense updated successfully');
                  }
                });
              },
              tooltip: 'Edit Expense',
            ),
          if (_expense != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(),
              tooltip: 'Delete Expense',
            ),
        ],
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Expense',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExpenseDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_expense == null) {
      return const Center(
        child: Text('Expense not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(isDarkMode),
          const SizedBox(height: 16),
          _buildDetailsCard(isDarkMode),
          const SizedBox(height: 16),
          _buildItemsCard(isDarkMode),
          const SizedBox(height: 16),
          _buildMetadataCard(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4158D0),
            Color(0xFFC850C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4158D0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _expense!.name ?? 'Unnamed Expense',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_expense!.totalAmount ?? 0.0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_expense!.description?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _expense!.description!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expense Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Category', _expense!.categoryName ?? 'Uncategorized'),
            _buildDetailRow('Line', _expense!.lineName ?? 'Common Expense'),
            _buildDetailRow('Priority', _formatPriority(_expense!.priority)),
            _buildDetailRow('Start Date', _formatDateFromString(_expense!.startDate)),
            _buildDetailRow('End Date', _formatDateFromString(_expense!.endDate)),
            if (_expense!.vendorName?.isNotEmpty == true) _buildDetailRow('Vendor', _expense!.vendorName!),
            if (_expense!.addedByName?.isNotEmpty == true) _buildDetailRow('Added By', _expense!.addedByName!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(bool isDarkMode) {
    if (_expense!.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.list_alt,
                  color: AppColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expense Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._expense!.items.map((item) => _buildItemRow(item)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _formatCurrency(_expense!.totalAmount ?? 0.0),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    String name;
    double price;

    if (item is ExpenseItemModel) {
      // If it's a proper ExpenseItemModel object
      name = item.name ?? 'Unknown Item';
      price = item.price ?? 0.0;
    } else if (item is Map<String, dynamic>) {
      // If it's a Map (for backward compatibility)
      name = item['name'] as String? ?? 'Unknown Item';
      price = (item['price'] as num?)?.toDouble() ?? 0.0;
    } else {
      // Fallback for unknown types
      name = 'Unknown Item';
      price = 0.0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatCurrency(price),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Created', _formatDateTimeFromString(_expense!.createdAt)),
            _buildDetailRow('Updated', _formatDateTimeFromString(_expense!.updatedAt)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${_expense!.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteExpense();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense() async {
    if (_expense?.id == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _repository.deleteExpense(expenseId: _expense!.id!);

    // Hide loading
    if (mounted) Navigator.of(context).pop();

    result.fold(
      (failure) {
        Utility.toast(message: 'Error deleting expense: ${failure.message}');
      },
      (success) {
        Utility.toast(message: 'Expense deleted successfully');
        if (mounted) context.pop(true); // Return true to indicate deletion
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  String _formatDateFromString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not specified';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDateTimeFromString(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'Not specified';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatPriority(ExpensePriority? priority) {
    if (priority == null) return 'Medium';
    switch (priority) {
      case ExpensePriority.low:
        return 'Low';
      case ExpensePriority.medium:
        return 'Medium';
      case ExpensePriority.high:
        return 'High';
      case ExpensePriority.critical:
        return 'Critical';
    }
  }
}
