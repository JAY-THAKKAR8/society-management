import 'package:flutter/material.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/reports/service/report_service.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_gradient_button.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class SocietyOverviewReportPage extends StatefulWidget {
  const SocietyOverviewReportPage({super.key});

  @override
  State<SocietyOverviewReportPage> createState() => _SocietyOverviewReportPageState();
}

class _SocietyOverviewReportPageState extends State<SocietyOverviewReportPage> {
  final IMaintenanceRepository _maintenanceRepository = getIt<IMaintenanceRepository>();
  final IUserRepository _userRepository = getIt<IUserRepository>();

  bool _isLoading = false;
  final Map<String, List<MaintenancePaymentModel>> _linePayments = {};
  final Map<String, List<UserModel>> _lineMembers = {};
  List<MaintenancePeriodModel> _periods = [];
  UserModel? _currentUser;

  final List<String> _lines = [
    AppConstants.firstLine,
    AppConstants.secondLine,
    AppConstants.thirdLine,
    AppConstants.fourthLine,
    AppConstants.fifthLine,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load current user (admin)
      final userResult = await _userRepository.getCurrentUser();
      userResult.fold(
        (failure) => {}, // Ignore user loading failure
        (user) => _currentUser = user,
      );

      // Load all periods
      final periodsResult = await _maintenanceRepository.getAllMaintenancePeriods();
      periodsResult.fold(
        (failure) => Utility.toast(message: 'Error loading periods: ${failure.message}'),
        (periods) => _periods = periods,
      );

      // Load all users and group by line
      final usersResult = await _userRepository.getAllUsers();
      usersResult.fold(
        (failure) => Utility.toast(message: 'Error loading users: ${failure.message}'),
        (users) {
          // Group users by line (excluding admins)
          for (final line in _lines) {
            _lineMembers[line] =
                users.where((user) => user.lineNumber == line && user.role != 'admin' && user.role != 'ADMIN').toList();
          }
        },
      );

      // Load payments for all lines
      for (final line in _lines) {
        List<MaintenancePaymentModel> linePayments = [];
        for (final period in _periods) {
          if (period.id != null) {
            final paymentsResult = await _maintenanceRepository.getPaymentsForLine(
              periodId: period.id!,
              lineNumber: line,
            );
            paymentsResult.fold(
              (failure) => {}, // Ignore individual failures
              (payments) => linePayments.addAll(payments),
            );
          }
        }
        _linePayments[line] = linePayments;
      }
    } catch (e) {
      Utility.toast(message: 'Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_linePayments.isEmpty || _lineMembers.isEmpty) {
      Utility.toast(message: 'No data available for report generation');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reportFile = await ReportService.generateSocietyOverviewPDF(
        linePayments: _linePayments,
        lineMembers: _lineMembers,
        periods: _periods,
        adminName: _currentUser?.name,
      );

      await ReportService.shareReport(reportFile, 'Society Overview');
      Utility.toast(message: 'Society overview report generated successfully!');
    } catch (e) {
      Utility.toast(message: 'Error generating report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Society Overview Report',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(context),
                    const SizedBox(height: 24),

                    // Society Summary
                    _buildSocietySummary(context),
                    const SizedBox(height: 24),

                    // Line-wise Performance
                    _buildLinePerformance(context),
                    const SizedBox(height: 24),

                    // Generate Report Button
                    _buildGenerateButton(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return ThemeAwareCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: Color(0xFF10B981),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Society Overview',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comprehensive report including all lines with detailed analytics',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocietySummary(BuildContext context) {
    // Calculate society totals
    double totalAmount = 0;
    double totalPaid = 0;
    int totalMembers = 0;

    _linePayments.forEach((line, payments) {
      totalAmount += payments.fold<double>(0, (sum, p) => sum + (p.amount ?? 0));
      totalPaid += payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
    });

    _lineMembers.forEach((line, members) {
      totalMembers += members.length;
    });

    final totalPending = totalAmount - totalPaid;
    final collectionRate = totalAmount > 0 ? (totalPaid / totalAmount * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Society Financial Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            _buildSummaryCard(
              'Total Amount',
              '₹${totalAmount.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              const Color(0xFF3B82F6),
            ),
            _buildSummaryCard(
              'Amount Collected',
              '₹${totalPaid.toStringAsFixed(2)}',
              Icons.check_circle,
              const Color(0xFF10B981),
            ),
            _buildSummaryCard(
              'Amount Pending',
              '₹${totalPending.toStringAsFixed(2)}',
              Icons.pending,
              const Color(0xFFEF4444),
            ),
            _buildSummaryCard(
              'Collection Rate',
              '${collectionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              collectionRate >= 85
                  ? const Color(0xFF10B981)
                  : collectionRate >= 70
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
            ),
            _buildSummaryCard(
              'Total Members',
              '$totalMembers',
              Icons.group,
              const Color(0xFF8B5CF6),
            ),
            _buildSummaryCard(
              'Active Periods',
              '${_periods.length}',
              Icons.calendar_month,
              const Color(0xFF06B6D4),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return ThemeAwareCard(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinePerformance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line-wise Performance Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._lines.map((line) => _buildLineCard(context, line)),
      ],
    );
  }

  Widget _buildLineCard(BuildContext context, String lineNumber) {
    final payments = _linePayments[lineNumber] ?? [];
    final members = _lineMembers[lineNumber] ?? [];

    final totalAmount = payments.fold<double>(0, (sum, p) => sum + (p.amount ?? 0));
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
    final totalPending = totalAmount - totalPaid;
    final collectionRate = totalAmount > 0 ? (totalPaid / totalAmount * 100) : 0.0;
    final paidMembers = payments.where((p) => p.status == PaymentStatus.paid).map((p) => p.userId).toSet().length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ThemeAwareCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.home_work,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lineNumber.toUpperCase().replaceAll('_', ' '),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${members.length} members • ${collectionRate.toStringAsFixed(1)}% collection rate',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: collectionRate >= 85
                          ? const Color(0xFF10B981)
                          : collectionRate >= 70
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      collectionRate >= 85
                          ? 'Excellent'
                          : collectionRate >= 70
                              ? 'Good'
                              : 'Needs Attention',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Financial Details
              Row(
                children: [
                  Expanded(
                    child: _buildLineDetailCard(
                      'Total Amount',
                      '₹${totalAmount.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLineDetailCard(
                      'Collected',
                      '₹${totalPaid.toStringAsFixed(2)}',
                      Icons.check_circle,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLineDetailCard(
                      'Pending',
                      '₹${totalPending.toStringAsFixed(2)}',
                      Icons.pending,
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Member Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildLineDetailCard(
                      'Total Members',
                      '${members.length}',
                      Icons.group,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLineDetailCard(
                      'Paid Members',
                      '$paidMembers',
                      Icons.person,
                      const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLineDetailCard(
                      'Pending Members',
                      '${members.length - paidMembers}',
                      Icons.person_off,
                      const Color(0xFFDC2626),
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

  Widget _buildLineDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CommonGradientButton(
        text: _isLoading ? 'Generating Report...' : 'Generate Society Overview Report',
        onPressed: _isLoading ? null : _generateReport,
      ),
    );
  }
}
