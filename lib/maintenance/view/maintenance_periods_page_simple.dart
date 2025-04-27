import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/add_maintenance_period_page.dart';
import 'package:society_management/maintenance/view/auto_maintenance_settings_page.dart';
import 'package:society_management/maintenance/view/improved_active_maintenance_stats_page.dart';
import 'package:society_management/maintenance/view/maintenance_payments_page.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class MaintenancePeriodsPageSimple extends StatefulWidget {
  const MaintenancePeriodsPageSimple({super.key});

  @override
  State<MaintenancePeriodsPageSimple> createState() => _MaintenancePeriodsPageSimpleState();
}

class _MaintenancePeriodsPageSimpleState extends State<MaintenancePeriodsPageSimple> {
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
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final userRepository = getIt<IUserRepository>();
      final userResult = await userRepository.getCurrentUser();

      if (!mounted) return;

      userResult.fold(
        (failure) {
          Utility.toast(message: failure.message);
          _fetchMaintenancePeriods(); // Continue with fetching data even if user fetch fails
        },
        (user) {
          if (mounted) {
            setState(() {
              _currentUser = user;
              _isAdmin = user.role == 'ADMIN' || user.role?.toLowerCase() == 'admin';
              // Make sure LINE_HEAD_MEMBER is not treated as admin
            });
          }
          _fetchMaintenancePeriods();
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error fetching user data: $e');
      if (mounted) {
        _fetchMaintenancePeriods(); // Continue with fetching data even if user fetch fails
      }
    }
  }

  Future<void> _fetchMaintenancePeriods() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final maintenanceRepository = getIt<IMaintenanceRepository>();
      final result = await maintenanceRepository.getAllMaintenancePeriods();

      if (!mounted) return;

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = failure.message;
            });
          }
          Utility.toast(message: failure.message);
        },
        (periods) {
          if (mounted) {
            setState(() {
              _periods = periods;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error fetching maintenance periods: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
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
              backgroundColor: const Color(0xFF0D47A1), // Deep blue for trading apps
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMaintenancePeriods,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_periods.isEmpty) {
      return Center(
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
      );
    }

    // Use a simple ListView with basic cards inside a SafeArea
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          // Add physics to ensure proper scrolling behavior
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _periods.length,
          itemBuilder: (context, index) {
            try {
              final period = _periods[index];
              return _buildSimplePeriodCard(period);
            } catch (e) {
              // If there's an error building a specific card, return an error card instead
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.red.withAlpha(50),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error displaying period: $e'),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSimplePeriodCard(MaintenancePeriodModel period) {
    // Handle null or invalid dates safely
    String dueDate = 'N/A';

    try {
      if (period.dueDate != null) {
        dueDate = DateFormat('MMM d, yyyy').format(DateTime.parse(period.dueDate!));
      }
    } catch (e) {
      // Invalid date format, keep default 'N/A'
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          try {
            if (period.id != null) {
              context.push(MaintenancePaymentsPage(
                periodId: period.id!,
                initialLineFilter: _isAdmin ? null : _currentUser?.lineNumber,
              ));
            } else {
              Utility.toast(message: 'Cannot view payments: Invalid period ID');
            }
          } catch (e) {
            Utility.toast(message: 'Error navigating to payments: $e');
          }
        },
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
              if (period.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  period.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.greyText,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.greyText,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${period.amount?.toStringAsFixed(2) ?? '0.00'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dueDate,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_isAdmin)
                    ElevatedButton(
                      onPressed: () {
                        if (period.id != null) {
                          context.push(
                            AddMaintenancePeriodPage(periodId: period.id),
                          );
                        } else {
                          Utility.toast(message: 'Cannot edit: Invalid period ID');
                        }
                      },
                      child: const Text('Edit'),
                    ),
                  if (_isAdmin) const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        if (period.id != null) {
                          context.push(MaintenancePaymentsPage(
                            periodId: period.id!,
                            initialLineFilter: _isAdmin ? null : _currentUser?.lineNumber,
                          ));
                        } else {
                          Utility.toast(message: 'Cannot view payments: Invalid period ID');
                        }
                      } catch (e) {
                        Utility.toast(message: 'Error navigating to payments: $e');
                      }
                    },
                    child: const Text('View Payments'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
