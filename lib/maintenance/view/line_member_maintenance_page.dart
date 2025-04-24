import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class LineMemberMaintenancePage extends StatefulWidget {
  final String? lineNumber;

  const LineMemberMaintenancePage({
    super.key,
    this.lineNumber,
  });

  @override
  State<LineMemberMaintenancePage> createState() => _LineMemberMaintenancePageState();
}

class _LineMemberMaintenancePageState extends State<LineMemberMaintenancePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MaintenancePeriodModel> _periods = [];
  List<MaintenancePaymentModel> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.lineNumber == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Line number not provided';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get active maintenance periods
      final maintenanceRepository = getIt<IMaintenanceRepository>();
      final periodsResult = await maintenanceRepository.getActiveMaintenancePeriods();

      periodsResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (periods) async {
          _periods = periods;

          if (periods.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Get payments for the most recent period
          final latestPeriod = periods.first;
          final paymentsResult = await maintenanceRepository.getPaymentsForPeriod(
            periodId: latestPeriod.id!,
          );

          paymentsResult.fold(
            (failure) {
              setState(() {
                _isLoading = false;
                _errorMessage = failure.message;
              });
              Utility.toast(message: failure.message);
            },
            (payments) {
              // Filter payments for this line
              final linePayments = payments
                  .where(
                    (payment) => payment.userLineNumber == widget.lineNumber,
                  )
                  .toList();

              setState(() {
                _payments = linePayments;
                _isLoading = false;
              });
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Line Maintenance Status',
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
                        onPressed: _fetchData,
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
                            'No active maintenance periods',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'There are no active maintenance periods to display',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final currentPeriod = _periods.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPeriodInfoCard(currentPeriod),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Line Members (${_payments.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _payments.isEmpty
              ? const Center(
                  child: Text('No members found in this line'),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(_payments[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPeriodInfoCard(MaintenancePeriodModel period) {
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

    return Card(
      margin: const EdgeInsets.all(16),
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
            Text(
              period.name ?? 'Current Maintenance Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (period.description != null && period.description!.isNotEmpty) ...[
              Text(
                period.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            _buildInfoRow('Amount', '₹${period.amount?.toStringAsFixed(2) ?? '0.00'}'),
            const SizedBox(height: 8),
            _buildInfoRow('Period', '$formattedStartDate to $formattedEndDate'),
            const SizedBox(height: 8),
            _buildInfoRow('Due Date', formattedDueDate),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Status',
              'Line members paid: ${_getPaymentStats()}',
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentStats() {
    if (_payments.isEmpty) return '0/0';

    final paidCount =
        _payments.where((p) => p.status == PaymentStatus.paid || p.status == PaymentStatus.partiallyPaid).length;

    return '$paidCount/${_payments.length}';
  }

  Widget _buildPaymentCard(MaintenancePaymentModel payment) {
    // Status color
    Color statusColor;
    String statusText;

    switch (payment.status) {
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
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    payment.userName ?? 'Unknown User',
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
            const SizedBox(height: 8),
            if (payment.userVillaNumber != null) _buildInfoRow('Villa', payment.userVillaNumber!),
            const SizedBox(height: 8),
            _buildInfoRow('Amount', '₹${payment.amount != null ? payment.amount!.toStringAsFixed(2) : '0.00'}'),
            const SizedBox(height: 8),
            _buildInfoRow('Paid', '₹${payment.amountPaid.toStringAsFixed(2)}'),
            if (payment.paymentDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Payment Date',
                DateFormat('MMM d, yyyy').format(DateTime.parse(payment.paymentDate!)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
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
