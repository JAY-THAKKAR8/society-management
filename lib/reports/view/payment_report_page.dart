import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/reports/service/report_service.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_gradient_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class PaymentReportPage extends StatefulWidget {
  final String lineNumber;

  const PaymentReportPage({
    super.key,
    required this.lineNumber,
  });

  @override
  State<PaymentReportPage> createState() => _PaymentReportPageState();
}

class _PaymentReportPageState extends State<PaymentReportPage> {
  final IMaintenanceRepository _maintenanceRepository = getIt<IMaintenanceRepository>();

  bool _isLoading = false;
  List<MaintenancePaymentModel> _payments = [];
  List<MaintenancePeriodModel> _periods = [];

  String _selectedReportType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<Map<String, String>> _reportTypes = [
    {'value': 'all', 'label': 'All Payments'},
    {'value': 'paid', 'label': 'Paid Payments'},
    {'value': 'pending', 'label': 'Pending Payments'},
    {'value': 'overdue', 'label': 'Overdue Payments'},
    {'value': 'partially_paid', 'label': 'Partially Paid'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all periods
      final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();
      periodsResult.fold(
        (failure) => Utility.toast(message: 'Error loading periods: ${failure.message}'),
        (periods) => _periods = periods,
      );

      // Load payments for all periods for this line
      List<MaintenancePaymentModel> allPayments = [];
      for (final period in _periods) {
        if (period.id != null) {
          final paymentsResult = await _maintenanceRepository.getPaymentsForLine(
            periodId: period.id!,
            lineNumber: widget.lineNumber,
          );
          paymentsResult.fold(
            (failure) => {}, // Ignore individual failures
            (payments) => allPayments.addAll(payments),
          );
        }
      }
      _payments = allPayments;
    } catch (e) {
      Utility.toast(message: 'Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_payments.isEmpty) {
      Utility.toast(message: 'No payment data available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reportFile = await ReportService.generatePaymentReportPDF(
        payments: _payments,
        periods: _periods,
        lineNumber: widget.lineNumber,
        reportType: _selectedReportType,
        startDate: _startDate?.toString(),
        endDate: _endDate?.toString(),
      );

      await ReportService.shareReport(reportFile, 'Payment');
      Utility.toast(message: 'Payment report generated successfully!');
    } catch (e) {
      Utility.toast(message: 'Error generating report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Payment Report - ${widget.lineNumber.toUpperCase().replaceAll('_', ' ')}',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode ? [AppColors.darkBackground, const Color(0xFF121428)] : AppColors.gradientGreenTeal,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportTypeSection(),
                      const SizedBox(height: 20),
                      _buildDateRangeSection(),
                      const SizedBox(height: 20),
                      _buildSummarySection(),
                      const SizedBox(height: 20),
                      _buildPreviewSection(),
                      const SizedBox(height: 30),
                      _buildGenerateButton(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildReportTypeSection() {
    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...(_reportTypes.map((type) => RadioListTile<String>(
                title: Text(type['label']!),
                value: type['value']!,
                groupValue: _selectedReportType,
                onChanged: (value) {
                  setState(() => _selectedReportType = value!);
                },
                activeColor: AppColors.primaryGreen,
              ))),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date Range (Optional)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Start Date',
                  _startDate,
                  () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateSelector(
                  'End Date',
                  _endDate,
                  () => _selectDate(false),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: const Text('Clear Dates'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select Date',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final filteredPayments = ReportService.filterPaymentsByType(_payments, _selectedReportType);
    final totalAmount = filteredPayments.fold<double>(0, (sum, payment) => sum + (payment.amount ?? 0));
    final totalPaid = filteredPayments.fold<double>(0, (sum, payment) => sum + payment.amountPaid);
    final totalPending = totalAmount - totalPaid;

    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Records', '${filteredPayments.length}', AppColors.primaryBlue)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _buildSummaryCard('Total Amount', '₹${totalAmount.toStringAsFixed(2)}', AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildSummaryCard('Amount Paid', '₹${totalPaid.toStringAsFixed(2)}', AppColors.lightGreen)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Amount Pending', '₹${totalPending.toStringAsFixed(2)}', Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final filteredPayments = ReportService.filterPaymentsByType(_payments, _selectedReportType);

    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview (First 5 Records)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (filteredPayments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No payments found for selected criteria'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Member')),
                  DataColumn(label: Text('Villa')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filteredPayments.take(5).map((payment) {
                  return DataRow(
                    cells: [
                      DataCell(Text(payment.userName ?? 'N/A')),
                      DataCell(Text(payment.userVillaNumber ?? 'N/A')),
                      DataCell(Text('₹${(payment.amount ?? 0).toStringAsFixed(2)}')),
                      DataCell(Text('₹${payment.amountPaid.toStringAsFixed(2)}')),
                      DataCell(_buildStatusChip(payment.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          if (filteredPayments.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${filteredPayments.length - 5} more records',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    Color color;
    String text;

    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        text = 'Paid';
        break;
      case PaymentStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case PaymentStatus.overdue:
        color = Colors.red;
        text = 'Overdue';
        break;
      case PaymentStatus.partiallyPaid:
        color = Colors.blue;
        text = 'Partial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: CommonGradientButton(
        text: _isLoading ? 'Generating...' : 'Generate & Share Report',
        onPressed: _isLoading ? null : _generateReport,
        gradientColors: AppColors.gradientGreenTeal,
        icon: _isLoading ? null : Icons.picture_as_pdf,
      ),
    );
  }
}
