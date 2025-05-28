import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/reports/service/report_service.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_gradient_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class MemberReportPage extends StatefulWidget {
  final String lineNumber;

  const MemberReportPage({
    super.key,
    required this.lineNumber,
  });

  @override
  State<MemberReportPage> createState() => _MemberReportPageState();
}

class _MemberReportPageState extends State<MemberReportPage> {
  final IUserRepository _userRepository = getIt<IUserRepository>();
  final IMaintenanceRepository _maintenanceRepository = getIt<IMaintenanceRepository>();

  bool _isLoading = false;
  List<UserModel> _members = [];
  List<MaintenancePaymentModel> _payments = [];

  String _selectedReportType = 'all';

  final List<Map<String, String>> _reportTypes = [
    {'value': 'all', 'label': 'All Members'},
    {'value': 'active', 'label': 'Active Members'},
    {'value': 'inactive', 'label': 'Inactive Members'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all users and filter by line
      final usersResult = await _userRepository.getAllUsers();
      usersResult.fold(
        (failure) => Utility.toast(message: 'Error loading users: ${failure.message}'),
        (users) {
          // Filter users by line number (excluding admins)
          _members = users
              .where((user) => user.lineNumber == widget.lineNumber && user.role != 'admin' && user.role != 'ADMIN')
              .toList();
        },
      );

      // Load all periods to get payments for this line
      final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();
      List<MaintenancePaymentModel> allPayments = [];

      periodsResult.fold(
        (failure) => Utility.toast(message: 'Error loading periods: ${failure.message}'),
        (periods) async {
          // Load payments for all periods for this line
          for (final period in periods) {
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
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_members.isEmpty) {
      Utility.toast(message: 'No member data available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reportFile = await ReportService.generateMemberReportPDF(
        members: _members,
        payments: _payments,
        lineNumber: widget.lineNumber,
        reportType: _selectedReportType,
      );

      await ReportService.shareReport(reportFile, 'Member');
      Utility.toast(message: 'Member report generated successfully!');
    } catch (e) {
      Utility.toast(message: 'Error generating report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<UserModel> _filterMembersByType(List<UserModel> members, String reportType) {
    switch (reportType.toLowerCase()) {
      case 'active':
        return members.where((m) => m.isVillaOpen == 'yes').toList();
      case 'inactive':
        return members.where((m) => m.isVillaOpen == 'no').toList();
      default:
        return members;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Member Report - ${widget.lineNumber.toUpperCase().replaceAll('_', ' ')}',
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

  Widget _buildSummarySection() {
    final filteredMembers = _filterMembersByType(_members, _selectedReportType);
    final activeMembers = filteredMembers.where((m) => m.isVillaOpen == 'yes').length;
    final inactiveMembers = filteredMembers.where((m) => m.isVillaOpen == 'no').length;

    // Calculate total payments for filtered members
    final memberIds = filteredMembers.map((m) => m.id).toSet();
    final memberPayments = _payments.where((p) => memberIds.contains(p.userId)).toList();
    final totalPaid = memberPayments.fold<double>(0, (sum, p) => sum + p.amountPaid);

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
              Expanded(child: _buildSummaryCard('Total Members', '${filteredMembers.length}', AppColors.primaryBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Active Members', '$activeMembers', AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Inactive Members', '$inactiveMembers', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildSummaryCard('Total Paid', '₹${totalPaid.toStringAsFixed(2)}', AppColors.lightGreen)),
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
    final filteredMembers = _filterMembersByType(_members, _selectedReportType);

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
          if (filteredMembers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No members found for selected criteria'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Villa')),
                  DataColumn(label: Text('Mobile')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Total Paid')),
                ],
                rows: filteredMembers.take(5).map((member) {
                  final memberPayments = _payments.where((p) => p.userId == member.id).toList();
                  final totalPaid = memberPayments.fold<double>(0, (sum, p) => sum + p.amountPaid);

                  return DataRow(
                    cells: [
                      DataCell(Text(member.name ?? 'N/A')),
                      DataCell(Text(member.villNumber ?? 'N/A')),
                      DataCell(Text(member.mobileNumber ?? 'N/A')),
                      DataCell(_buildStatusChip(member.isVillaOpen == 'yes')),
                      DataCell(Text('₹${totalPaid.toStringAsFixed(2)}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          if (filteredMembers.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${filteredMembers.length - 5} more records',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? Colors.green : Colors.orange;
    final text = isActive ? 'Active' : 'Inactive';

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
