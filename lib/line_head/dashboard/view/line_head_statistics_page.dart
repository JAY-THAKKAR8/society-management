import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/maintenance_payments_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_app_bar.dart';

class LineHeadStatisticsPage extends StatefulWidget {
  final String lineNumber;

  const LineHeadStatisticsPage({
    super.key,
    required this.lineNumber,
  });

  @override
  State<LineHeadStatisticsPage> createState() => _LineHeadStatisticsPageState();
}

class _LineHeadStatisticsPageState extends State<LineHeadStatisticsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MaintenancePeriodModel> _activePeriods = [];
  final Map<String, _PeriodStats> _periodStats = {};
  late final IMaintenanceRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = getIt<IMaintenanceRepository>();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get active periods
      final periodsResult = await _repository.getActiveMaintenancePeriods();

      periodsResult.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        },
        (periods) async {
          _activePeriods = periods;

          // Get statistics for each period for this line
          for (final period in periods) {
            if (period.id != null) {
              final paymentsResult = await _repository.getPaymentsForPeriod(periodId: period.id!);

              paymentsResult.fold(
                (failure) {
                  // Handle individual period failure
                },
                (payments) {
                  // Filter payments for this line only
                  final linePayments =
                      payments.where((payment) => payment.userLineNumber == widget.lineNumber).toList();

                  _periodStats[period.id!] = _calculatePeriodStats(period, linePayments);
                },
              );
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
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  _PeriodStats _calculatePeriodStats(MaintenancePeriodModel period, List<MaintenancePaymentModel> payments) {
    final totalAmount = period.amount?.toDouble() ?? 0;
    double collectedAmount = 0;
    double lateFees = 0;
    int paidCount = 0;
    int pendingCount = 0;
    int totalMembers = 0;

    // Group payments by user
    final userPayments = <String, List<MaintenancePaymentModel>>{};
    for (final payment in payments) {
      final userId = payment.userId;
      if (userId != null) {
        if (!userPayments.containsKey(userId)) {
          userPayments[userId] = [];
        }
        userPayments[userId]!.add(payment);
      }
    }

    totalMembers = userPayments.length;

    for (final userPaymentList in userPayments.values) {
      double userPaidAmount = 0;
      double userLateFees = 0;

      for (final payment in userPaymentList) {
        userPaidAmount += payment.amount ?? 0;
        userLateFees += payment.lateFeeAmount;
      }

      collectedAmount += userPaidAmount;
      lateFees += userLateFees;

      if (userPaidAmount >= totalAmount) {
        paidCount++;
      } else {
        pendingCount++;
      }
    }

    final pendingAmount = (totalAmount * totalMembers) - collectedAmount;

    return _PeriodStats(
      totalAmount: totalAmount * totalMembers,
      collectedAmount: collectedAmount,
      pendingAmount: pendingAmount,
      lateFees: lateFees,
      paidCount: paidCount,
      pendingCount: pendingCount,
      totalMembers: totalMembers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Line ${widget.lineNumber} Statistics',
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
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    if (_activePeriods.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No active maintenance periods found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallSummary(),
          const SizedBox(height: 24),
          Text(
            'Period-wise Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._buildPeriodCards(),
        ],
      ),
    );
  }

  Widget _buildOverallSummary() {
    double totalCollected = 0;
    double totalPending = 0;
    double totalLateFees = 0;
    int totalPaidMembers = 0;
    int totalPendingMembers = 0;

    for (final stats in _periodStats.values) {
      totalCollected += stats.collectedAmount;
      totalPending += stats.pendingAmount;
      totalLateFees += stats.lateFees;
      totalPaidMembers += stats.paidCount;
      totalPendingMembers += stats.pendingCount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Line ${widget.lineNumber} - All Active Periods',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Collected',
                  '₹${totalCollected.toStringAsFixed(2)}',
                  Icons.check_circle,
                  Colors.green.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  '₹${totalPending.toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.orange.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Late Fees',
                  '₹${totalLateFees.toStringAsFixed(2)}',
                  Icons.schedule,
                  Colors.red.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Members',
                  '$totalPaidMembers paid / $totalPendingMembers pending',
                  Icons.people,
                  Colors.blue.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPeriodCards() {
    final widgets = <Widget>[];

    for (final period in _activePeriods) {
      if (period.id != null && _periodStats.containsKey(period.id!)) {
        widgets.add(_buildPeriodCard(period, _periodStats[period.id!]!));
        widgets.add(const SizedBox(height: 16));
      }
    }

    if (widgets.isNotEmpty) {
      widgets.removeLast(); // Remove last SizedBox
    }

    return widgets;
  }

  Widget _buildPeriodCard(MaintenancePeriodModel period, _PeriodStats stats) {
    final collectionPercentage = stats.totalAmount > 0 ? (stats.collectedAmount / stats.totalAmount) * 100 : 0.0;

    final urgencyColor = collectionPercentage > 80
        ? Colors.green
        : collectionPercentage > 50
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              urgencyColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: urgencyColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          period.name ?? 'Unnamed Period',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (period.dueDate != null)
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(DateTime.parse(period.dueDate!))}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${collectionPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Collection Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${stats.paidCount}/${stats.totalMembers} members',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: urgencyColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: collectionPercentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Statistics grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Collected',
                      '₹${stats.collectedAmount.toStringAsFixed(2)}',
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      '₹${stats.pendingAmount.toStringAsFixed(2)}',
                      urgencyColor,
                      Icons.pending,
                    ),
                  ),
                ],
              ),

              if (stats.lateFees > 0) ...[
                const SizedBox(height: 12),
                _buildStatCard(
                  'Late Fees Collected',
                  '₹${stats.lateFees.toStringAsFixed(2)}',
                  Colors.orange,
                  Icons.schedule,
                  fullWidth: true,
                ),
              ],

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      MaintenancePaymentsPage(
                        periodId: period.id!,
                        initialLineFilter: widget.lineNumber,
                        initialStatusFilter: 'all',
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Payment Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodStats {
  final double totalAmount;
  final double collectedAmount;
  final double pendingAmount;
  final double lateFees;
  final int paidCount;
  final int pendingCount;
  final int totalMembers;

  _PeriodStats({
    required this.totalAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.lateFees,
    required this.paidCount,
    required this.pendingCount,
    required this.totalMembers,
  });
}
