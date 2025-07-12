import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/expenses/model/recurring_expense_model.dart';
import 'package:society_management/expenses/service/expense_service.dart';
import 'package:society_management/expenses/view/add_recurring_expense_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class RecurringExpensesPage extends StatefulWidget {
  const RecurringExpensesPage({super.key});

  @override
  State<RecurringExpensesPage> createState() => _RecurringExpensesPageState();
}

class _RecurringExpensesPageState extends State<RecurringExpensesPage> {
  bool _isLoading = true;
  List<RecurringExpenseModel> _recurringExpenses = [];
  double _totalMonthlyAmount = 0.0;
  int _overdueCount = 0;
  int _dueSoonCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      print('Loading monthly fixed expenses...'); // Debug log

      // Load monthly fixed expenses from Firebase
      final expenses = await RecurringExpenseService.instance.getMonthlyFixedExpenses();

      print('Received ${expenses.length} expenses from service'); // Debug log
      for (final expense in expenses) {
        print('- ${expense.name}: ₹${expense.amount}'); // Debug log
      }

      setState(() {
        _recurringExpenses = expenses;
        _calculateStatistics();
        _isLoading = false;
      });

      print('UI updated with ${expenses.length} expenses'); // Debug log
    } catch (e) {
      print('Error loading recurring expenses: $e');

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expenses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _recurringExpenses = [];
        _calculateStatistics();
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    _totalMonthlyAmount =
        _recurringExpenses.where((expense) => expense.isActive).fold(0.0, (sum, expense) => sum + expense.amount);

    final now = DateTime.now();
    _overdueCount = _recurringExpenses
        .where((expense) => expense.nextDueDate != null && expense.nextDueDate!.isBefore(now) && expense.isActive)
        .length;

    final dueSoonDate = now.add(const Duration(days: 7));
    _dueSoonCount = _recurringExpenses
        .where((expense) =>
            expense.nextDueDate != null &&
            expense.nextDueDate!.isAfter(now) &&
            expense.nextDueDate!.isBefore(dueSoonDate) &&
            expense.isActive)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: CommonAppBar(
        title: '💰 Monthly Fixed Expenses',
        showDivider: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await RecurringExpenseService.instance.debugExpensesCollection();
              Utility.toast(message: 'Debug info printed to console');
            },
            tooltip: 'Debug Expenses',
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: _showMonthlyDashboard,
            tooltip: 'Monthly Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(const AddRecurringExpensePage());
          _loadData();
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Recurring'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(isDark),
                    const Gap(20),
                    _buildQuickStatsCards(isDark),
                    const Gap(24),
                    _buildExpenseTypeCards(isDark),
                    const Gap(24),
                    _buildExpensesList(isDark),
                    const Gap(100), // Space for FAB
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
            AppColors.primaryBlue.withValues(alpha: 0.8),
            AppColors.primaryPurple.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
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
              const Icon(Icons.autorenew_rounded, color: Colors.white, size: 28),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Fixed Expenses',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(8),
          const Text(
            'Manage monthly fixed expenses like security, utilities, and maintenance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              const Icon(Icons.currency_rupee, color: Colors.white, size: 20),
              const Gap(4),
              Text(
                '${NumberFormat('#,##,###').format(_totalMonthlyAmount)}/month',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Active',
            value: '${_recurringExpenses.where((e) => e.isActive).length}',
            icon: Icons.check_circle_outline,
            color: AppColors.primaryGreen,
            isDark: isDark,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            title: 'Overdue',
            value: '$_overdueCount',
            icon: Icons.warning_outlined,
            color: AppColors.primaryRed,
            isDark: isDark,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            title: 'Due Soon',
            value: '$_dueSoonCount',
            icon: Icons.schedule_outlined,
            color: AppColors.primaryOrange,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const Gap(8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTypeCards(bool isDark) {
    const expenseTypes = RecurringExpenseType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Gap(12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: expenseTypes.length,
          itemBuilder: (context, index) {
            final type = expenseTypes[index];
            final count = _recurringExpenses.where((expense) => expense.type == type && expense.isActive).length;

            return GestureDetector(
              onTap: () => _filterByType(type),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const Gap(4),
                    Text(
                      type.displayName.split(' ').first,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (count > 0) ...[
                      const Gap(2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpensesList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Recurring Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSortOptions(),
              icon: const Icon(Icons.sort_rounded, size: 16),
              label: const Text('Sort'),
            ),
          ],
        ),
        const Gap(12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recurringExpenses.length,
          itemBuilder: (context, index) {
            final expense = _recurringExpenses[index];
            return _buildExpenseCard(expense, isDark);
          },
        ),
      ],
    );
  }

  void _filterByType(RecurringExpenseType type) {
    Utility.toast(message: 'Filtering by ${type.displayName}');
  }

  void _showSortOptions() {
    Utility.toast(message: 'Sort options coming soon');
  }

  void _markAsPaid(RecurringExpenseModel expense) {
    _showMarkPaidDialog(expense);
  }

  void _editExpense(RecurringExpenseModel expense) {
    _showEditDialog(expense);
  }

  void _showMarkPaidDialog(RecurringExpenseModel expense) {
    final amountController = TextEditingController(text: expense.amount.toString());
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const Gap(12),
              const Expanded(
                child: Text(
                  'Mark as Paid',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expense Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(expense.type.emoji, style: const TextStyle(fontSize: 20)),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              expense.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (expense.vendorName != null) ...[
                        const Gap(4),
                        Text(
                          'Vendor: ${expense.vendorName}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                      const Gap(4),
                      Text(
                        'Scheduled: ₹${NumberFormat('#,##,###').format(expense.amount)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const Gap(16),

                // Payment Month/Year
                const Text('Payment Month/Year:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          return DropdownMenuItem(
                            value: month,
                            child: Text(_getMonthName(month)),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(3, (index) {
                          final year = DateTime.now().year - 1 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedYear = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const Gap(16),

                // Payment Date
                const Text('Payment Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Gap(8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const Gap(8),
                        Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),

                const Gap(16),

                // Actual Amount Paid
                const Text('Actual Amount Paid:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Gap(8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                    hintText: 'Enter amount paid',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const Gap(16),

                // Notes
                const Text('Notes (Optional):', style: TextStyle(fontWeight: FontWeight.w600)),
                const Gap(8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Any additional notes...',
                  ),
                  maxLines: 2,
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
                final actualAmount = double.tryParse(amountController.text);
                if (actualAmount == null || actualAmount <= 0) {
                  Utility.toast(message: 'Please enter a valid amount');
                  return;
                }

                Navigator.of(context).pop();

                // Show loading
                Utility.toast(message: 'Recording payment...');

                try {
                  // First check if already paid for this month/year
                  final alreadyPaid = await RecurringExpenseService.instance.isExpenseAlreadyPaid(
                    expenseId: expense.id!,
                    paidMonth: selectedMonth,
                    paidYear: selectedYear,
                  );

                  if (alreadyPaid) {
                    Utility.toast(
                        message: '⚠️ Already paid ${expense.name} for ${_getMonthName(selectedMonth)} $selectedYear');
                    return;
                  }

                  // Mark as paid in Firebase using the new monthly expense method
                  final success = await RecurringExpenseService.instance.markMonthlyFixedExpenseAsPaid(
                    expenseId: expense.id!,
                    expenseName: expense.name,
                    amount: expense.amount,
                    paidDate: selectedDate,
                    paidMonth: selectedMonth,
                    paidYear: selectedYear,
                    actualAmount: actualAmount,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    paidBy: 'Admin', // TODO: Get from auth service
                  );

                  if (success) {
                    print('Payment successful, refreshing data...'); // Debug log

                    // Show success message
                    Utility.toast(message: '✅ Payment recorded for ${_getMonthName(selectedMonth)} $selectedYear!');

                    // Show payment confirmation
                    _showPaymentConfirmation(
                        expense, actualAmount, selectedDate, selectedMonth, selectedYear, notesController.text.trim());

                    // Force refresh all dashboard stats
                    await RecurringExpenseService.instance.refreshAllDashboardStats();

                    // Refresh the data to ensure consistency
                    await _loadData();
                  } else {
                    Utility.toast(message: '❌ Failed to record payment');
                  }
                } catch (e) {
                  print('Error recording payment: $e');
                  Utility.toast(message: '❌ Error recording payment: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(RecurringExpenseModel expense) {
    final nameController = TextEditingController(text: expense.name);
    final amountController = TextEditingController(text: expense.amount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Expense Name',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading
              Utility.toast(message: 'Updating expense...');

              try {
                // Update expense in Firebase using RecurringExpenseService
                final success = await RecurringExpenseService.instance.updateMonthlyFixedExpense(
                  expenseId: expense.id!,
                  name: nameController.text.trim(),
                  amount: double.tryParse(amountController.text),
                );

                if (success) {
                  // Refresh the data to ensure consistency
                  await _loadData();

                  Utility.toast(message: '✅ ${expense.name} updated successfully!');
                } else {
                  Utility.toast(message: '❌ Failed to update ${expense.name}');
                }
              } catch (e) {
                print('Error updating expense: $e');
                Utility.toast(message: '❌ Error updating expense: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(RecurringExpenseModel expense, bool isDark) {
    Color statusColor = AppColors.primaryBlue;
    String statusText = 'Monthly Fixed';
    Color cardBackgroundColor = isDark ? Colors.grey[800]! : Colors.white;
    Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(expense.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  expense.type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (expense.vendorName != null) ...[
                      const Gap(2),
                      Text(
                        expense.vendorName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${NumberFormat('#,##,###').format(expense.amount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const Gap(2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[600]),
              const Gap(4),
              Text(
                'Due: ${expense.nextDueDate != null ? DateFormat('MMM dd, yyyy').format(expense.nextDueDate!) : 'Not set'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (expense.contactNumber != null) ...[
                Icon(Icons.phone_rounded, size: 14, color: Colors.grey[600]),
                const Gap(4),
                Text(
                  expense.contactNumber!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markAsPaid(expense),
                  icon: const Icon(Icons.payment_rounded, size: 16),
                  label: const Text('Mark Paid'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const Gap(8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _editExpense(expense),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const Gap(8),
              IconButton(
                onPressed: () => showDeleteConfirmation(expense),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Expense',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(RecurringExpenseType type) {
    switch (type) {
      case RecurringExpenseType.security:
        return AppColors.primaryBlue;
      case RecurringExpenseType.electricity:
        return AppColors.primaryOrange;
      case RecurringExpenseType.water:
        return Colors.blue;
      case RecurringExpenseType.garden:
        return AppColors.primaryGreen;
      case RecurringExpenseType.cleaning:
        return AppColors.primaryPurple;
      case RecurringExpenseType.maintenance:
        return Colors.brown;
      case RecurringExpenseType.salary:
        return Colors.teal;
      case RecurringExpenseType.other:
        return Colors.grey;
    }
  }

  void _showPaymentConfirmation(RecurringExpenseModel expense, double actualAmount, DateTime paidDate, int paidMonth,
      int paidYear, String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const Gap(12),
            const Text('Payment Recorded'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment for ${expense.name} has been successfully recorded.',
              style: const TextStyle(fontSize: 16),
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Amount Paid:', '₹${NumberFormat('#,##,###').format(actualAmount)}'),
                  _buildInfoRow('Payment Date:', DateFormat('MMM dd, yyyy').format(paidDate)),
                  _buildInfoRow('Paid For:', '${_getMonthName(paidMonth)} $paidYear'),
                  if (notes.isNotEmpty) _buildInfoRow('Notes:', notes),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showPaymentHistory(expense);
            },
            icon: const Icon(Icons.history, size: 16),
            label: const Text('View History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showPaymentHistory(RecurringExpenseModel expense) async {
    try {
      // Get payment history from service
      final paymentHistory = await RecurringExpenseService.instance.getExpensePaymentHistory(
        expenseId: expense.id!,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment History'),
                    Text(
                      expense.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: paymentHistory.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                        Gap(16),
                        Text('No payments recorded yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: paymentHistory.length,
                    itemBuilder: (context, index) {
                      final payment = paymentHistory[index];
                      final paidDate = (payment['paid_date'] as Timestamp).toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_getMonthName(payment['paid_month'])} ${payment['paid_year']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(payment['amount'])}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              'Paid on: ${DateFormat('MMM dd, yyyy').format(paidDate)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (payment['notes'] != null && payment['notes'].toString().isNotEmpty) ...[
                              const Gap(4),
                              Text(
                                'Notes: ${payment['notes']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Utility.toast(message: 'Error loading payment history: $e');
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  void _showMonthlyDashboard() async {
    try {
      final now = DateTime.now();

      // Get actual payment data from Firebase for current month
      final monthYear = '${now.month}-${now.year}';
      final dashboardDoc =
          await FirebaseFirestore.instance.collection('monthly_expense_dashboard').doc(monthYear).get();

      double totalPaid = 0.0;
      List<Map<String, dynamic>> paidExpensesList = [];

      if (dashboardDoc.exists) {
        final data = dashboardDoc.data()!;
        totalPaid = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
        paidExpensesList = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
      }

      // Calculate total pending (all expenses minus paid ones)
      final totalExpenses = _recurringExpenses.fold(0.0, (total, e) => total + e.amount);
      final totalPending = totalExpenses; // All expenses are pending until paid for specific month

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard_outlined,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Dashboard'),
                    Text(
                      '${_getMonthName(now.month)} ${now.year}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                            const Gap(4),
                            Text(
                              '₹${NumberFormat('#,##,###').format(totalPaid)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text('Paid', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.pending, color: AppColors.primaryOrange, size: 20),
                            const Gap(4),
                            Text(
                              '₹${NumberFormat('#,##,###').format(totalPending)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text('Pending', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Gap(16),

                // Paid Expenses List
                if (paidExpensesList.isNotEmpty) ...[
                  const Text('✅ Paid Expenses (This Month):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Gap(8),
                  ...paidExpensesList.map((expense) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 16),
                            const Gap(8),
                            Expanded(child: Text(expense['name'] ?? 'Unknown', style: const TextStyle(fontSize: 14))),
                            Text('₹${NumberFormat('#,##,###').format(expense['amount'] ?? 0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      )),
                  const Gap(12),
                ],

                // All Available Expenses List
                if (_recurringExpenses.isNotEmpty) ...[
                  const Text('📋 All Monthly Fixed Expenses:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Gap(8),
                  ..._recurringExpenses.map((expense) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(expense.type.emoji, style: const TextStyle(fontSize: 16)),
                            const Gap(8),
                            Expanded(child: Text(expense.name, style: const TextStyle(fontSize: 14))),
                            Text('₹${NumberFormat('#,##,###').format(expense.amount)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Utility.toast(message: 'Error loading monthly dashboard: $e');
    }
  }

  void showDeleteConfirmation(RecurringExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const Gap(12),
            const Text('Delete Expense'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${expense.name}"?',
              style: const TextStyle(fontSize: 16),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_outlined, color: Colors.red, size: 20),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All payment history for this expense will also be deleted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading
              Utility.toast(message: 'Deleting expense...');

              try {
                // Delete from Firebase using RecurringExpenseService
                print('Attempting to delete expense: ${expense.name} with ID: ${expense.id}'); // Debug log
                final success = await RecurringExpenseService.instance.deleteMonthlyFixedExpense(
                  expenseId: expense.id!,
                );

                if (success) {
                  print('Delete successful, refreshing data...'); // Debug log

                  // Refresh the entire list from Firebase to ensure consistency
                  await _loadData();

                  Utility.toast(message: '✅ ${expense.name} deleted successfully!');
                } else {
                  Utility.toast(message: '❌ Failed to delete ${expense.name}');
                }
              } catch (e) {
                print('Error deleting expense: $e');
                Utility.toast(message: '❌ Error deleting expense: $e');
              }
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
}
