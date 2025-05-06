import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
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
  // Map to store line-specific maintenance data
  final Map<String, Map<String, double>> _lineMaintenanceData = {};

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
            // Fix admin role check to be more inclusive
            _isAdmin = user.role == AppConstants.admin || // 'ADMIN'
                user.role == AppConstants.admins || // 'Admin'
                user.role?.toLowerCase() == 'admin';

            // Use Utility.toast for debugging instead of print
            Utility.toast(message: 'User role: ${user.role}, Is admin: $_isAdmin');
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
        (periods) async {
          _periods = periods;

          // If user is a line head, fetch line-specific data
          if (_currentUser != null && _currentUser!.isLineHead && !_isAdmin) {
            final lineNumber = _currentUser!.lineNumber;
            if (lineNumber != null) {
              await _fetchLineSpecificData(periods, lineNumber);
            }
          }

          setState(() {
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

  Future<void> _fetchLineSpecificData(List<MaintenancePeriodModel> periods, String lineNumber) async {
    try {
      final maintenanceRepository = getIt<IMaintenanceRepository>();

      for (final period in periods) {
        if (period.id == null) continue;

        // Get payments for this line and period
        final paymentsResult = await maintenanceRepository.getPaymentsForLine(
          periodId: period.id!,
          lineNumber: lineNumber,
        );

        paymentsResult.fold(
          (failure) {
            Utility.toast(message: 'Error fetching line data: ${failure.message}');
          },
          (payments) {
            double totalCollected = 0.0;
            double totalPending = 0.0;

            for (final payment in payments) {
              final amount = payment.amount ?? 0.0;
              final amountPaid = payment.amountPaid;

              totalCollected += amountPaid;
              totalPending += (amount - amountPaid);
            }

            // Store line-specific data
            _lineMaintenanceData[period.id!] = {
              'totalCollected': totalCollected,
              'totalPending': totalPending,
            };
          },
        );
      }
    } catch (e) {
      Utility.toast(message: 'Error fetching line data: $e');
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
                              shrinkWrap: true,
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

    // Determine if we should use line-specific data or global data
    double totalCollected = period.totalCollected;
    double totalPending = period.totalPending;
    String displayTitle = 'Collection Progress';

    // If user is a line head (but not admin) and we have line-specific data, use it
    if (_currentUser != null &&
        _currentUser!.isLineHead &&
        !_isAdmin &&
        period.id != null &&
        _lineMaintenanceData.containsKey(period.id)) {
      final lineData = _lineMaintenanceData[period.id!]!;
      totalCollected = lineData['totalCollected'] ?? 0.0;
      totalPending = lineData['totalPending'] ?? 0.0;
      displayTitle = 'Line ${_currentUser!.userLineViewString} Collection Progress';
    }

    final collectionPercentage =
        (totalCollected + totalPending) > 0 ? (totalCollected / (totalCollected + totalPending)) * 100 : 0.0;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? AppColors.darkCard : AppColors.lightContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: period.isActive
              ? Colors.green.withAlpha(isDarkMode ? 100 : 150)
              : isDarkMode
                  ? Colors.white.withAlpha(25)
                  : AppColors.lightDivider,
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
              Text(
                displayTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              // Row(
              //   children: [
              //     Text(
              //       displayTitle,
              //       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //             fontWeight: FontWeight.bold,
              //           ),
              //     ),
              //     const SizedBox(width: 0),
              //     Container(
              //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              //       decoration: BoxDecoration(
              //         color: Colors.amber.withAlpha(50),
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       child: Text(
              //         'Due: $dueDate',
              //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //               color: Colors.amber,
              //               fontWeight: FontWeight.bold,
              //               fontSize: 10,
              //             ),
              //       ),
              //     ),
              //   ],
              // ),
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
                    'Collected: ₹${totalCollected.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                  Text(
                    'Pending: ₹${totalPending.toStringAsFixed(2)}',
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
