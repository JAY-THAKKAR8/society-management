import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/maintenance_payments_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

class LineWiseMaintenanceStatsPage extends StatefulWidget {
  final String periodId;
  final String periodName;

  const LineWiseMaintenanceStatsPage({
    super.key,
    required this.periodId,
    required this.periodName,
  });

  @override
  State<LineWiseMaintenanceStatsPage> createState() => _LineWiseMaintenanceStatsPageState();
}

class _LineWiseMaintenanceStatsPageState extends State<LineWiseMaintenanceStatsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  MaintenancePeriodModel? _period;
  List<MaintenancePaymentModel> _allPayments = [];
  final Map<String, List<MaintenancePaymentModel>> _linePayments = {};
  final Map<String, _LineStats> _lineStats = {};

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

      // Fetch period details
      final periodResult = await maintenanceRepository.getMaintenancePeriod(
        periodId: widget.periodId,
      );

      // Fetch all payments for this period
      final paymentsResult = await maintenanceRepository.getPaymentsForPeriod(
        periodId: widget.periodId,
      );

      periodResult.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
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
            _isLoading = false;
          });
          Utility.toast(message: failure.message);
        },
        (payments) {
          // Filter out admin users
          _allPayments = payments.where((payment) {
            final isAdmin = payment.userId == 'admin' ||
                payment.userName?.toLowerCase() == 'admin' ||
                payment.userId?.toLowerCase().contains('admin') == true ||
                payment.userName?.toLowerCase().contains('admin') == true;
            return !isAdmin;
          }).toList();

          // Group payments by line
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

    // Group payments by line
    for (final payment in _allPayments) {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Line Statistics: ${widget.periodName}',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 100, // Subtract app bar height
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSummary(),
            const SizedBox(height: 24),
            Text(
              'Line-wise Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Wrap the dynamic content in a Column with proper constraints
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _buildLineStatCards(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSummary() {
    if (_period == null) return const SizedBox.shrink();

    final collectionPercentage = _period!.amount != null && _period!.amount! > 0
        ? (_period!.totalCollected / (_period!.totalCollected + _period!.totalPending)) * 100
        : 0.0;

    return Card(
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _period!.isActive ? Colors.green.withAlpha(100) : Colors.white.withAlpha(25),
          width: _period!.isActive ? 1.5 : 1.0,
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
                    _period!.name ?? 'Unnamed Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _period!.isActive ? Colors.green.withAlpha(50) : Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _period!.isActive ? 'Active' : 'Inactive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _period!.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Amount',
                    '₹${_period!.amount?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Start Date',
                    _period!.startDate != null
                        ? DateFormat('MMM d, yyyy').format(DateTime.parse(_period!.startDate!))
                        : 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Due Date',
                    _period!.dueDate != null
                        ? DateFormat('MMM d, yyyy').format(DateTime.parse(_period!.dueDate!))
                        : 'N/A',
                    isHighlighted: true,
                  ),
                ),
              ],
            ),
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
                  'Collected: ₹${_period!.totalCollected.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                ),
                Text(
                  'Pending: ₹${_period!.totalPending.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.push(MaintenancePaymentsPage(periodId: widget.periodId));
                  },
                  icon: const Icon(Icons.payments, size: 18),
                  label: const Text('View All Payments'),
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
                ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      MaintenancePaymentsPage(
                        periodId: widget.periodId,
                        initialLineFilter: lineNumber,
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
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

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value, {
    bool isHighlighted = false,
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
