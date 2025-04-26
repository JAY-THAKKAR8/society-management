import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class AllActiveMaintenanceStatsPage extends StatefulWidget {
  const AllActiveMaintenanceStatsPage({super.key});

  @override
  State<AllActiveMaintenanceStatsPage> createState() => _AllActiveMaintenanceStatsPageState();
}

class _AllActiveMaintenanceStatsPageState extends State<AllActiveMaintenanceStatsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MaintenancePeriodModel> _activePeriods = [];
  final Map<String, List<MaintenancePaymentModel>> _periodPayments = {};
  final Map<String, List<MaintenancePaymentModel>> _linePayments = {};
  final Map<String, _LineStats> _lineStats = {};
  double _totalCollected = 0.0;
  double _totalPending = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final maintenanceRepository = getIt<IMaintenanceRepository>();

      // Fetch all active maintenance periods
      final periodsResult = await maintenanceRepository.getActiveMaintenancePeriods();

      await periodsResult.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
          Utility.toast(message: failure.message);
        },
        (periods) async {
          _activePeriods = periods;
          _periodPayments.clear();

          if (periods.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Fetch payments for each active period
          for (final period in periods) {
            if (period.id == null) continue;

            final paymentsResult = await maintenanceRepository.getPaymentsForPeriod(
              periodId: period.id!,
            );

            paymentsResult.fold(
              (failure) {
                // Just log the error but continue with other periods
                Utility.toast(message: 'Error loading payments for period ${period.name}: ${failure.message}');
              },
              (payments) {
                // Filter out admin users
                final filteredPayments = payments.where((payment) {
                  final isAdmin = payment.userId == 'admin' ||
                      payment.userName?.toLowerCase() == 'admin' ||
                      payment.userId?.toLowerCase().contains('admin') == true ||
                      payment.userName?.toLowerCase().contains('admin') == true;
                  return !isAdmin;
                }).toList();

                _periodPayments[period.id!] = filteredPayments;
              },
            );
          }

          // Organize payments by line
          _organizePaymentsByLine();

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
      Utility.toast(message: 'Error fetching data: $e');
    }
  }

  void _organizePaymentsByLine() {
    _linePayments.clear();
    _lineStats.clear();
    _totalCollected = 0.0;
    _totalPending = 0.0;

    // Initialize with all possible lines
    final allLines = [
      AppConstants.firstLine,
      AppConstants.secondLine,
      AppConstants.thirdLine,
      AppConstants.fourthLine,
      AppConstants.fifthLine,
    ];

    for (final line in allLines) {
      _linePayments[line] = [];
      _lineStats[line] = _LineStats(
        totalAmount: 0,
        collectedAmount: 0,
        pendingAmount: 0,
        paidCount: 0,
        pendingCount: 0,
        totalCount: 0,
      );
    }

    // Process all payments from all active periods
    for (final periodId in _periodPayments.keys) {
      final payments = _periodPayments[periodId] ?? [];

      for (final payment in payments) {
        final lineNumber = payment.userLineNumber;
        if (lineNumber != null && _linePayments.containsKey(lineNumber)) {
          _linePayments[lineNumber]!.add(payment);

          // Update line stats
          final stats = _lineStats[lineNumber]!;
          final amount = payment.amount ?? 0.0;
          final amountPaid = payment.amountPaid;
          final isPaid = payment.status == PaymentStatus.paid;
          final isPending = payment.status == PaymentStatus.pending ||
              payment.status == PaymentStatus.overdue ||
              payment.status == PaymentStatus.partiallyPaid;

          stats.totalCount++;
          stats.totalAmount += amount;
          stats.collectedAmount += amountPaid;
          stats.pendingAmount += (amount - amountPaid);

          if (isPaid) {
            stats.paidCount++;
          } else if (isPending) {
            stats.pendingCount++;
          }

          // Update overall totals
          _totalCollected += amountPaid;
          _totalPending += (amount - amountPaid);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'All Active Maintenance Statistics',
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_activePeriods.isEmpty) {
      return const Center(
        child: Text('No active maintenance periods found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallSummary(),
            const SizedBox(height: 24),
            Text(
              'Line-wise Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._buildLineStatCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummary() {
    final collectionPercentage =
        (_totalCollected + _totalPending) > 0 ? (_totalCollected / (_totalCollected + _totalPending)) * 100 : 0.0;

    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.blue.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'All Active Maintenance Periods (${_activePeriods.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActivePeriodsList(),
            const SizedBox(height: 16),
            Text(
              'Overall Collection Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  'Collected: ₹${_totalCollected.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                ),
                Text(
                  'Pending: ₹${_totalPending.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePeriodsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _activePeriods.map((period) {
        // Get due date for display
        final dueDate =
            period.dueDate != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(period.dueDate!)) : 'N/A';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  period.name ?? 'Unnamed Period',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                'Due: $dueDate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildLineStatCards() {
    final widgets = <Widget>[];

    // Sort lines by line number
    final sortedLines = _lineStats.keys.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a) ?? 0;
        final bNum = int.tryParse(b) ?? 0;
        return aNum.compareTo(bNum);
      });

    for (final lineNumber in sortedLines) {
      final stats = _lineStats[lineNumber]!;

      // Skip lines with no members
      if (stats.totalCount == 0) continue;

      final collectionPercentage = stats.totalAmount > 0 ? (stats.collectedAmount / stats.totalAmount) * 100 : 0.0;

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColors.lightBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: AppColors.buttonColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Line ${_getLineText(lineNumber)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      'Members: ${stats.totalCount}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Total Amount',
                        '₹${stats.totalAmount.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Collected',
                        '₹${stats.collectedAmount.toStringAsFixed(2)}',
                        valueColor: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Pending',
                        '₹${stats.pendingAmount.toStringAsFixed(2)}',
                        valueColor: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMemberCountChip(
                      context,
                      'Paid',
                      stats.paidCount,
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildMemberCountChip(
                      context,
                      'Pending',
                      stats.pendingCount,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Show payments for this line across all active periods
                          _showLinePaymentsDialog(context, lineNumber);
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          foregroundColor: Colors.white,
                        ),
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

    if (widgets.isEmpty) {
      widgets.add(
        const Center(
          child: Text('No line statistics available'),
        ),
      );
    }

    return widgets;
  }

  void _showLinePaymentsDialog(BuildContext context, String lineNumber) {
    final linePayments = _linePayments[lineNumber] ?? [];

    if (linePayments.isEmpty) {
      Utility.toast(message: 'No payments found for Line $lineNumber');
      return;
    }

    // Group payments by period
    final paymentsByPeriod = <String, List<MaintenancePaymentModel>>{};
    for (final payment in linePayments) {
      final periodId = payment.periodId;
      if (periodId != null) {
        if (!paymentsByPeriod.containsKey(periodId)) {
          paymentsByPeriod[periodId] = [];
        }
        paymentsByPeriod[periodId]!.add(payment);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Line $lineNumber Payments',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _activePeriods.length,
                    itemBuilder: (context, index) {
                      final period = _activePeriods[index];
                      if (period.id == null) return const SizedBox.shrink();

                      final periodPayments = paymentsByPeriod[period.id] ?? [];
                      if (periodPayments.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period.name ?? 'Unnamed Period',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...periodPayments.map((payment) => _buildPaymentItem(context, payment)),
                          const Divider(),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentItem(BuildContext context, MaintenancePaymentModel payment) {
    final statusColor = payment.status == PaymentStatus.paid
        ? Colors.green
        : payment.status == PaymentStatus.partiallyPaid
            ? Colors.amber
            : Colors.red;

    final statusText = payment.status == PaymentStatus.paid
        ? 'Paid'
        : payment.status == PaymentStatus.partiallyPaid
            ? 'Partially Paid'
            : payment.status == PaymentStatus.overdue
                ? 'Overdue'
                : 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statusColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.userName ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Villa: ${payment.userVillaNumber ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${payment.amountPaid.toStringAsFixed(2)} / ₹${payment.amount?.toStringAsFixed(2) ?? '0.00'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.greyText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }

  Widget _buildMemberCountChip(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getLineText(String lineNumber) {
    switch (lineNumber) {
      case '1':
        return '1';
      case '2':
        return '2';
      case '3':
        return '3';
      case '4':
        return '4';
      case '5':
        return '5';
      default:
        return lineNumber;
    }
  }
}

class _LineStats {
  double totalAmount;
  double collectedAmount;
  double pendingAmount;
  int paidCount;
  int pendingCount;
  int totalCount;

  _LineStats({
    required this.totalAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.paidCount,
    required this.pendingCount,
    required this.totalCount,
  });
}
