import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class MyMaintenanceStatusPage extends StatefulWidget {
  const MyMaintenanceStatusPage({super.key});

  @override
  State<MyMaintenanceStatusPage> createState() => _MyMaintenanceStatusPageState();
}

class _MyMaintenanceStatusPageState extends State<MyMaintenanceStatusPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MaintenancePeriodModel> _periods = [];
  final Map<String, List<MaintenancePaymentModel>> _paymentsByPeriod = {};
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUserAndPayments();
  }

  Future<void> _getCurrentUserAndPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User data not available';
        });
        return;
      }

      _currentUser = user;

      // Get all maintenance periods
      final maintenanceRepository = getIt<IMaintenanceRepository>();
      final periodsResult = await maintenanceRepository.getAllMaintenancePeriods();

      await periodsResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (periods) async {
          _periods = periods;
          _paymentsByPeriod.clear();

          // For each period, get payments for this user
          for (final period in periods) {
            if (period.id == null) continue;

            final paymentsResult = await maintenanceRepository.getPaymentsForPeriod(
              periodId: period.id!,
            );

            paymentsResult.fold(
              (failure) {
                // Just log the error but continue
                Utility.toast(message: 'Error loading payments for period ${period.name}: ${failure.message}');
              },
              (payments) {
                // Filter payments for this user
                final userPayments = payments
                    .where(
                      (payment) => payment.userId == user.id,
                    )
                    .toList();

                if (userPayments.isNotEmpty) {
                  _paymentsByPeriod[period.id!] = userPayments;
                }
              },
            );
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
      Utility.toast(message: 'Error fetching maintenance data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'My Maintenance Status',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
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
                        onPressed: _getCurrentUserAndPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _periods.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No maintenance periods found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'There are no active maintenance periods',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _getCurrentUserAndPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _periods.length,
                        itemBuilder: (context, index) {
                          final period = _periods[index];
                          final payments = _paymentsByPeriod[period.id] ?? [];
                          return _buildPeriodCard(context, period, payments);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPeriodCard(
    BuildContext context,
    MaintenancePeriodModel period,
    List<MaintenancePaymentModel> payments,
  ) {
    // Format dates
    String formattedStartDate = 'Unknown';
    String formattedEndDate = 'Unknown';
    String formattedDueDate = 'Unknown';

    if (period.startDate != null) {
      try {
        final date = DateTime.parse(period.startDate!);
        formattedStartDate = DateFormat('MMM d, yyyy').format(date);
      } catch (e) {
        // Use default value
      }
    }

    if (period.endDate != null) {
      try {
        final date = DateTime.parse(period.endDate!);
        formattedEndDate = DateFormat('MMM d, yyyy').format(date);
      } catch (e) {
        // Use default value
      }
    }

    if (period.dueDate != null) {
      try {
        final date = DateTime.parse(period.dueDate!);
        formattedDueDate = DateFormat('MMM d, yyyy').format(date);
      } catch (e) {
        // Use default value
      }
    }

    // Payment status
    final payment = payments.isNotEmpty ? payments.first : null;
    final paymentStatus = payment?.status ?? PaymentStatus.pending;

    Color statusColor;
    String statusText;

    switch (paymentStatus) {
      case PaymentStatus.paid:
        statusColor = Colors.green;
        statusText = 'Paid';
        break;
      case PaymentStatus.partiallyPaid:
        statusColor = Colors.orange;
        statusText = 'Partially Paid';
        break;
      case PaymentStatus.overdue:
        statusColor = Colors.red;
        statusText = 'Overdue';
        break;
      case PaymentStatus.pending:
        statusColor = Colors.grey;
        statusText = 'Pending';
        break;
      // Default case is handled by pending case
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    period.name ?? 'Unnamed Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (period.description != null && period.description!.isNotEmpty) ...[
              Text(
                period.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(context, 'Amount', '₹${period.amount?.toStringAsFixed(2) ?? '0.00'}'),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Period', '$formattedStartDate to $formattedEndDate'),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Due Date', formattedDueDate),
            if (payment != null) ...[
              const Divider(height: 24),
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(context, 'Amount Paid', '₹${payment.amountPaid.toStringAsFixed(2)}'),
              if (payment.paymentDate != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Payment Date',
                  DateFormat('MMM d, yyyy').format(DateTime.parse(payment.paymentDate!)),
                ),
              ],
              if (payment.paymentMethod != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(context, 'Payment Method', payment.paymentMethod!),
              ],
              if (payment.collectorName != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(context, 'Collected By', payment.collectorName!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
