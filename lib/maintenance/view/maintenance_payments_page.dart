import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/record_payment_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class MaintenancePaymentsPage extends StatefulWidget {
  final String periodId;

  const MaintenancePaymentsPage({
    super.key,
    required this.periodId,
  });

  @override
  State<MaintenancePaymentsPage> createState() => _MaintenancePaymentsPageState();
}

class _MaintenancePaymentsPageState extends State<MaintenancePaymentsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  MaintenancePeriodModel? _period;
  List<MaintenancePaymentModel> _payments = [];
  String? _errorMessage;
  late TabController _tabController;
  String? _selectedLine;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final maintenanceRepository = getIt<IMaintenanceRepository>();

      // Fetch period details
      final periodResult = await maintenanceRepository.getMaintenancePeriod(
        periodId: widget.periodId,
      );

      // Fetch payments
      final paymentsResult = await maintenanceRepository.getPaymentsForPeriod(
        periodId: widget.periodId,
      );

      periodResult.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (period) {
          setState(() {
            _period = period;
          });
        },
      );

      paymentsResult.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (payments) {
          setState(() {
            _payments = payments;
          });
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error fetching data: $e');
    }
  }

  List<MaintenancePaymentModel> _getFilteredPayments() {
    if (_selectedLine == null) {
      return _payments;
    }

    return _payments.where((payment) => payment.userLineNumber == _selectedLine).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _period?.name ?? 'Maintenance Payments',
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
              : Column(
                  children: [
                    _buildPeriodSummary(),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'All Payments'),
                        Tab(text: 'By Line'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllPaymentsList(),
                          _buildLineFilteredList(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPeriodSummary() {
    if (_period == null) return const SizedBox.shrink();

    final collectionPercentage = _period!.amount != null && _period!.amount! > 0
        ? (_period!.totalCollected / (_period!.totalCollected + _period!.totalPending)) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.lightBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount: ₹${_period!.amount?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Due Date: '),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _period!.dueDate != null
                              ? DateFormat('MMM d, yyyy').format(DateTime.parse(_period!.dueDate!))
                              : 'N/A',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Last date for payment',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Collected: ₹${_period!.totalCollected.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text(
                    'Pending: ₹${_period!.totalPending.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
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
          Text(
            '${collectionPercentage.toStringAsFixed(1)}% collected',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAllPaymentsList() {
    final filteredPayments = _getFilteredPayments();

    if (filteredPayments.isEmpty) {
      return const Center(
        child: Text('No payments found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = filteredPayments[index];
        return _buildPaymentCard(context, payment);
      },
    );
  }

  Widget _buildLineFilteredList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Line',
              border: OutlineInputBorder(),
            ),
            value: _selectedLine,
            items: const [
              DropdownMenuItem<String>(
                value: null,
                child: Text('All Lines'),
              ),
              DropdownMenuItem<String>(
                value: AppConstants.firstLine,
                child: Text('Line 1'),
              ),
              DropdownMenuItem<String>(
                value: AppConstants.secondLine,
                child: Text('Line 2'),
              ),
              DropdownMenuItem<String>(
                value: AppConstants.thirdLine,
                child: Text('Line 3'),
              ),
              DropdownMenuItem<String>(
                value: AppConstants.fourthLine,
                child: Text('Line 4'),
              ),
              DropdownMenuItem<String>(
                value: AppConstants.fifthLine,
                child: Text('Line 5'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLine = value;
              });
            },
          ),
        ),
        Expanded(
          child: _buildAllPaymentsList(),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, MaintenancePaymentModel payment) {
    Color statusColor;
    switch (payment.status) {
      case PaymentStatus.paid:
        statusColor = Colors.green;
        break;
      case PaymentStatus.partiallyPaid:
        statusColor = Colors.amber;
        break;
      case PaymentStatus.overdue:
        statusColor = Colors.red;
        break;
      case PaymentStatus.pending:
        statusColor = Colors.grey;
        break;
    }

    String statusText;
    switch (payment.status) {
      case PaymentStatus.paid:
        statusText = 'Paid';
        break;
      case PaymentStatus.partiallyPaid:
        statusText = 'Partially Paid';
        break;
      case PaymentStatus.overdue:
        statusText = 'Overdue';
        break;
      case PaymentStatus.pending:
        statusText = 'Pending';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.userName ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Villa: ${payment.userVillaNumber ?? 'N/A'} | Line: ${_getLineText(payment.userLineNumber)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.greyText,
                            ),
                      ),
                    ],
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount: ₹${payment.amount?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (payment.amountPaid > 0)
                      Text(
                        'Paid: ₹${payment.amountPaid.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    if (payment.amount != null && payment.amount! > payment.amountPaid)
                      Text(
                        'Remaining: ₹${(payment.amount! - payment.amountPaid).toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
                if (payment.paymentDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Payment Date:'),
                      Text(
                        DateFormat('MMM d, yyyy').format(DateTime.parse(payment.paymentDate!)),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
            if (payment.collectorName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Collected by: ${payment.collectorName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await context.push(
                      RecordPaymentPage(
                        periodId: widget.periodId,
                        payment: payment,
                      ),
                    );
                    _fetchData();
                  },
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Record Payment'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLineText(String? lineNumber) {
    switch (lineNumber) {
      case AppConstants.firstLine:
        return 'Line 1';
      case AppConstants.secondLine:
        return 'Line 2';
      case AppConstants.thirdLine:
        return 'Line 3';
      case AppConstants.fourthLine:
        return 'Line 4';
      case AppConstants.fifthLine:
        return 'Line 5';
      default:
        return 'Unknown';
    }
  }
}
