import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/model/maintenance_stats_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/view/line_maintenance_details_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';
import 'package:society_management/widget/trading_style_button.dart';

class ImprovedActiveMaintenanceStatsPage extends StatefulWidget {
  const ImprovedActiveMaintenanceStatsPage({super.key});

  @override
  State<ImprovedActiveMaintenanceStatsPage> createState() => _ImprovedActiveMaintenanceStatsPageState();
}

class _ImprovedActiveMaintenanceStatsPageState extends State<ImprovedActiveMaintenanceStatsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MaintenancePeriodModel> _activePeriods = [];
  final Map<String, List<MaintenancePaymentModel>> _periodPayments = {};

  // Line stats - key is line number
  final Map<String, LineStatsModel> _lineStats = {};

  // User stats - key is userId
  final Map<String, UserStatsModel> _userStats = {};

  // Line member counts - to avoid double counting
  final Map<String, Set<String>> _lineMembers = {};

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
          _lineStats.clear();
          _userStats.clear();
          _lineMembers.clear();

          if (periods.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Initialize line stats
          final allLines = [
            AppConstants.firstLine,
            AppConstants.secondLine,
            AppConstants.thirdLine,
            AppConstants.fourthLine,
            AppConstants.fifthLine,
          ];

          for (final line in allLines) {
            _lineStats[line] = LineStatsModel(
              totalAmount: 0,
              collectedAmount: 0,
              pendingAmount: 0,
              memberCount: 0,
              paidCount: 0,
              pendingCount: 0,
            );
            _lineMembers[line] = {};
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

                // Process payments for this period
                _processPayments(filteredPayments, period);
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
      Utility.toast(message: 'Error fetching data: $e');
    }
  }

  void _processPayments(List<MaintenancePaymentModel> payments, MaintenancePeriodModel period) {
    for (final payment in payments) {
      final lineNumber = payment.userLineNumber;
      final userId = payment.userId;

      if (lineNumber == null || userId == null || !_lineStats.containsKey(lineNumber)) {
        continue;
      }

      // Add user to line members set to track unique members
      _lineMembers[lineNumber]!.add(userId);

      // Update line stats
      final stats = _lineStats[lineNumber]!;
      final amount = payment.amount ?? 0.0;
      final amountPaid = payment.amountPaid;
      final isPaid = payment.status == PaymentStatus.paid;
      final isPending = payment.status == PaymentStatus.pending ||
          payment.status == PaymentStatus.overdue ||
          payment.status == PaymentStatus.partiallyPaid;

      stats.totalAmount += amount;
      stats.collectedAmount += amountPaid;
      stats.pendingAmount += (amount - amountPaid);

      // Update user stats
      if (!_userStats.containsKey(userId)) {
        _userStats[userId] = UserStatsModel(
          userId: userId,
          userName: payment.userName ?? 'Unknown',
          villaNumber: payment.userVillaNumber,
          lineNumber: lineNumber,
          totalAmount: 0,
          totalPaid: 0,
          pendingPeriods: [],
        );
      }

      final userStats = _userStats[userId]!;
      userStats.totalAmount += amount;
      userStats.totalPaid += amountPaid;

      if (isPending) {
        userStats.pendingPeriods.add(PendingPeriodModel(
          periodId: period.id!,
          periodName: period.name ?? 'Unknown Period',
          amount: amount,
          amountPaid: amountPaid,
          dueDate: period.dueDate != null ? DateTime.parse(period.dueDate!) : null,
        ));
      }
    }

    // Update member counts after processing all payments
    for (final lineNumber in _lineStats.keys) {
      final stats = _lineStats[lineNumber]!;
      stats.memberCount = _lineMembers[lineNumber]!.length;

      // Count paid and pending members
      final paidMembers = <String>{};
      final pendingMembers = <String>{};

      for (final userId in _userStats.keys) {
        final userStats = _userStats[userId]!;
        if (userStats.lineNumber != lineNumber) continue;

        if (userStats.pendingPeriods.isEmpty) {
          paidMembers.add(userId);
        } else {
          pendingMembers.add(userId);
        }
      }

      stats.paidCount = paidMembers.length;
      stats.pendingCount = pendingMembers.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Maintenance Statistics',
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
                      TradingStyleButton(
                        text: 'Retry',
                        onPressed: _fetchData,
                        leadingIcon: Icons.refresh,
                        showChartIcons: false,
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 100, // Subtract app bar height
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivePeriodsSummary(),
              const SizedBox(height: 24),
              Text(
                'Line-wise Collection Status',
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
      ),
    );
  }

  Widget _buildActivePeriodsSummary() {
    return ThemeAwareCard(
      useContainerColor: true,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: ThemeUtils.getHighlightColor(context, Colors.blue, opacity: 0.3),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_month, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active Maintenance Periods',
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeUtils.getHighlightColor(context, Colors.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_activePeriods.length} Active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ..._activePeriods.map((period) {
            final dueDate =
                period.dueDate != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(period.dueDate!)) : 'N/A';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      period.name ?? 'Unnamed Period',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '₹${period.amount?.toStringAsFixed(0) ?? '0'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Due: $dueDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber,
                          ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
      if (stats.memberCount == 0) continue;

      final collectionPercentage = stats.totalAmount > 0 ? (stats.collectedAmount / stats.totalAmount) * 100 : 0.0;

      widgets.add(
        ThemeAwareCard(
          margin: const EdgeInsets.only(bottom: 16),
          useContainerColor: true,
          borderRadius: BorderRadius.circular(12),
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
                    'Line $lineNumber',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeUtils.getHighlightColor(context, Colors.blue),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${stats.memberCount} Members',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total Due',
                      '₹${stats.totalAmount.toStringAsFixed(0)}',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Collected',
                      '₹${stats.collectedAmount.toStringAsFixed(0)}',
                      valueColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Pending',
                      '₹${stats.pendingAmount.toStringAsFixed(0)}',
                      valueColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: collectionPercentage / 100,
                backgroundColor: ThemeUtils.isDarkMode(context) ? Colors.grey.withAlpha(50) : Colors.grey.withAlpha(30),
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
                    'Fully Paid',
                    stats.paidCount,
                    Colors.green,
                    lineNumber: lineNumber,
                  ),
                  const SizedBox(width: 8),
                  _buildMemberCountChip(
                    context,
                    'Pending',
                    stats.pendingCount,
                    Colors.red,
                    lineNumber: lineNumber,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TradingStyleButton(
                text: 'View Details',
                onPressed: () {
                  // Navigate to line details page with no filter (show all)
                  _navigateToLineDetails(lineNumber, filterType: 'all');
                },
              ),
            ],
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

  void _navigateToLineDetails(String lineNumber, {String? filterType}) {
    // Get users for this line
    final lineUsers = _userStats.values.where((user) => user.lineNumber == lineNumber).toList();

    // Navigate to line details page
    context.push(
      LineMaintenanceDetailsPage(
        lineNumber: lineNumber,
        users: lineUsers,
        activePeriods: _activePeriods,
        initialFilterType: filterType,
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
    Color color, {
    String? lineNumber,
  }) {
    return InkWell(
      onTap: lineNumber != null
          ? () {
              // Navigate to line details with filter
              final filterType = label == 'Fully Paid' ? 'paid' : 'pending';
              _navigateToLineDetails(lineNumber, filterType: filterType);
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(76)),
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
      ),
    );
  }
}
