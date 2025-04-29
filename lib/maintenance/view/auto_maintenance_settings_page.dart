import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/maintenance/service/auto_maintenance_service.dart';
import 'package:society_management/maintenance/service/maintenance_background_service.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';

class AutoMaintenanceSettingsPage extends StatefulWidget {
  const AutoMaintenanceSettingsPage({super.key});

  @override
  State<AutoMaintenanceSettingsPage> createState() => _AutoMaintenanceSettingsPageState();
}

class _AutoMaintenanceSettingsPageState extends State<AutoMaintenanceSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '1000.00');
  bool _isLoading = false;
  bool _isForceCheckLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _forceAutomaticCheck() async {
    setState(() {
      _isForceCheckLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final backgroundService = MaintenanceBackgroundService();
      await backgroundService.forceCheck();

      setState(() {
        _isForceCheckLoading = false;
        _successMessage = 'Automatic maintenance check completed successfully';
      });
      Utility.toast(message: 'Automatic check completed');
    } catch (e) {
      setState(() {
        _isForceCheckLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error: $e');
    }
  }

  Future<void> _createNextMonthPeriod() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? 1000.0;
      final autoService = AutoMaintenanceService();

      // Calculate current month's date for display
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final currentMonthName = DateFormat('MMMM yyyy').format(currentMonth);

      final result = await autoService.createCurrentMonthPeriod(defaultAmount: amount);

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (period) {
          setState(() {
            _isLoading = false;
            _successMessage = 'Successfully created maintenance period for $currentMonthName';
          });
          Utility.toast(message: 'Maintenance period created successfully');
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Auto Maintenance Settings',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 100, // Subtract app bar height
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildSettingsCard(),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                CommonButton(
                  text: 'Create Current Month Period Now',
                  isLoading: _isLoading,
                  onTap: _createNextMonthPeriod,
                ),
                const SizedBox(height: 16),
                CommonButton(
                  text: 'Force Automatic Check Now',
                  isLoading: _isForceCheckLoading,
                  onTap: _forceAutomaticCheck,
                  backgroundColor: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Automatic Maintenance Period Creation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The system is configured to automatically create a new maintenance period on the 27th of each month for the current month without any user interaction.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'For example, on April 27th, a new period for April will be created automatically in the background.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The system will also check for any missed periods when the app starts up to ensure no months are skipped.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You can also manually create the current month\'s period using the button below if needed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set the default amount for the next maintenance period. If not specified, the amount from the most recent period will be used.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
