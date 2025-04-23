import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/dashboard/widgets/summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/view/line_users_page.dart';
import 'package:society_management/utility/utility.dart';

class SummarySection extends StatefulWidget {
  const SummarySection({super.key});

  @override
  SummarySectionState createState() => SummarySectionState();
}

class SummarySectionState extends State<SummarySection> with WidgetsBindingObserver {
  DashboardStatsModel? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDashboardStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app is resumed
      _fetchDashboardStats();
    }
  }

  // Public method to refresh stats from outside
  void refreshStats() {
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch dashboard stats from repository
      final statsRepository = getIt<IDashboardStatsRepository>();
      final result = await statsRepository.getDashboardStats();

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          Utility.toast(message: failure.message);
        },
        (stats) {
          setState(() {
            _stats = stats;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      Utility.toast(message: 'Error fetching dashboard stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Dashboard Summary",
              style: theme.textTheme.titleLarge,
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchDashboardStats,
                tooltip: 'Refresh dashboard stats',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.group,
                title: "Total Members",
                value: _isLoading
                    ? "Loading..."
                    : _stats != null
                        ? "${_stats!.totalMembers}"
                        : "0",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LineUsersPage(),
                    ),
                  );
                },
              ),
            ),
            const Gap(16),
            const Expanded(
              child: SummaryCard(
                icon: Icons.monetization_on,
                title: "Pending Dues",
                value: "₹24,000",
              ),
            ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.inventory,
                title: "Total Expenses",
                value: _isLoading
                    ? "Loading..."
                    : _stats != null
                        ? "₹${_stats!.totalExpenses.toStringAsFixed(2)}"
                        : "₹0",
              ),
            ),
            const Gap(16),
            const Expanded(
              child: SummaryCard(
                icon: Icons.report_problem,
                title: "Open Complaints",
                value: "8",
              ),
            ),
          ],
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Error: $_errorMessage",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
