import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/add_maintenance_period_page.dart';
import 'package:society_management/maintenance/view/auto_maintenance_settings_page.dart';
import 'package:society_management/maintenance/view/improved_active_maintenance_stats_page.dart';
import 'package:society_management/maintenance/view/line_wise_maintenance_stats_page.dart';
import 'package:society_management/maintenance/view/maintenance_payments_page.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class MaintenancePeriodsPage extends StatefulWidget {
  const MaintenancePeriodsPage({super.key});

  @override
  State<MaintenancePeriodsPage> createState() => _MaintenancePeriodsPageState();
}

class _MaintenancePeriodsPageState extends State<MaintenancePeriodsPage> {
  bool _isLoading = true;
  List<MaintenancePeriodModel> _periods = [];
  String? _errorMessage;
  bool _isAdmin = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUserAndFetchData();
  }

  Future<void> _getCurrentUserAndFetchData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userRepository = getIt<IUserRepository>();
      final userResult = await userRepository.getCurrentUser();

      userResult.fold(
        (failure) {
          Utility.toast(message: failure.message);
          _fetchMaintenancePeriods(); // Continue with fetching data even if user fetch fails
        },
        (user) {
          setState(() {
            _currentUser = user;
            _isAdmin = user.role == 'ADMIN' || user.role?.toLowerCase() == 'admin';
          });
          _fetchMaintenancePeriods();
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error fetching user data: $e');
      _fetchMaintenancePeriods(); // Continue with fetching data even if user fetch fails
    }
  }

  Future<void> _fetchMaintenancePeriods() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final maintenanceRepository = getIt<IMaintenanceRepository>();
      final result = await maintenanceRepository.getAllMaintenancePeriods();

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (periods) {
          setState(() {
            _periods = periods;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error fetching maintenance periods: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Maintenance Periods',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.analytics),
                  tooltip: 'View All Active Statistics',
                  onPressed: () {
                    context.push(const ImprovedActiveMaintenanceStatsPage());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Auto Maintenance Settings',
                  onPressed: () {
                    context.push(const AutoMaintenanceSettingsPage());
                  },
                ),
              ]
            : null,
      ),
      // Only show add button for admin users
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await context.push(const AddMaintenancePeriodPage());
                _fetchMaintenancePeriods();
              },
              backgroundColor: AppColors.buttonColor,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMaintenancePeriods,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Main content
                    Expanded(
                      child: _periods.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 64,
                                    color: AppColors.greyText,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No maintenance periods found',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add a maintenance period to start collecting payments',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.greyText,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _periods.length,
                              itemBuilder: (context, index) {
                                final period = _periods[index];
                                return _buildPeriodCard(context, period);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPeriodCard(BuildContext context, MaintenancePeriodModel period) {
    final startDate =
        period.startDate != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(period.startDate!)) : 'N/A';
    final dueDate = period.dueDate != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(period.dueDate!)) : 'N/A';

    final collectionPercentage = period.amount != null && period.amount! > 0
        ? (period.totalCollected / (period.totalCollected + period.totalPending)) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: period.isActive ? Colors.green.withAlpha(100) : Colors.white.withAlpha(25),
          width: period.isActive ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(MaintenancePaymentsPage(
            periodId: period.id!,
            initialLineFilter: _isAdmin ? null : _currentUser?.lineNumber,
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      period.name ?? 'Unnamed Period',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: period.isActive ? Colors.green.withAlpha(50) : Colors.grey.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      period.isActive ? 'Active' : 'Inactive',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: period.isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (period.description != null)
                Text(
                  period.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.greyText,
                      ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Amount',
                      '₹${period.amount?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Start Date',
                      startDate,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Due Date',
                      dueDate,
                      isHighlighted: true,
                      subtitle: 'Payment Deadline',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Collection Progress',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Due: $dueDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: collectionPercentage / 100,
                backgroundColor: Colors.grey.withAlpha(50),
                valueColor: AlwaysStoppedAnimation<Color>(
                  collectionPercentage > 75
                      ? Colors.green
                      : collectionPercentage > 50
                          ? Colors.amber
                          : Colors.red,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${collectionPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Collected: ₹${period.totalCollected.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                  Text(
                    'Pending: ₹${period.totalPending.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Only show edit button for admin users
                  if (_isAdmin)
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to edit page
                        context.push(
                          AddMaintenancePeriodPage(periodId: period.id),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  if (_isAdmin) const SizedBox(width: 8),
                  // Only show line stats button for admin users
                  if (_isAdmin)
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to line stats page
                        context.push(
                          LineWiseMaintenanceStatsPage(
                            periodId: period.id!,
                            periodName: period.name ?? 'Unnamed Period',
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('Line Stats'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  if (_isAdmin) const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to payments page
                      context.push(MaintenancePaymentsPage(
                        periodId: period.id!,
                        initialLineFilter: _isAdmin ? null : _currentUser?.lineNumber,
                      ));
                    },
                    icon: const Icon(Icons.payments, size: 18),
                    label: const Text('Payments'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value, {
    bool isHighlighted = false,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isHighlighted ? Colors.amber : AppColors.greyText,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.greyText,
                  fontSize: 10,
                ),
          ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.amber : null,
              ),
        ),
      ],
    );
  }
}
