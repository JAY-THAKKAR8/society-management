import 'package:flutter/material.dart';
import 'package:society_management/dashboard/model/dashboard_stats_model.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/dashboard/widgets/improved_summary_card.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/users/view/line_users_page.dart';
import 'package:society_management/utility/utility.dart';

class ImprovedSummarySection extends StatefulWidget {
  const ImprovedSummarySection({super.key});

  @override
  ImprovedSummarySectionState createState() => ImprovedSummarySectionState();
}

class ImprovedSummarySectionState extends State<ImprovedSummarySection> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardStatsModel? _stats;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    refreshStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> refreshStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

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
          _animationController.forward();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: refreshStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard Overview",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Total Members Card
        ImprovedSummaryCard(
          icon: Icons.group,
          title: "Total Members",
          value: _stats != null ? "${_stats!.totalMembers}" : "0",
          startColor: const Color(0xFF4158D0),
          endColor: const Color(0xFFC850C0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LineUsersPage(),
              ),
            );
          },
        ),
        
        // Maintenance Dues Card
        ImprovedSummaryCard(
          icon: Icons.monetization_on,
          title: "Maintenance Dues",
          value: _stats != null ? "₹${_stats!.maintenancePending.toStringAsFixed(2)}" : "₹0",
          startColor: const Color(0xFFFF416C),
          endColor: const Color(0xFFFF4B2B),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MaintenancePeriodsPage(),
              ),
            );
          },
        ),
        
        // Total Expenses Card
        ImprovedSummaryCard(
          icon: Icons.inventory,
          title: "Total Expenses",
          value: _stats != null ? "₹${_stats!.totalExpenses.toStringAsFixed(2)}" : "₹0",
          startColor: const Color(0xFF43CEA2),
          endColor: const Color(0xFF185A9D),
        ),
        
        // Collected Payment Card
        ImprovedSummaryCard(
          icon: Icons.payments,
          title: "Collected Payment",
          value: _stats != null ? "₹${_stats!.maintenanceCollected.toStringAsFixed(2)}" : "₹0",
          startColor: const Color(0xFF56CCF2),
          endColor: const Color(0xFF2F80ED),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MaintenancePeriodsPage(),
              ),
            );
          },
        ),
        
        // Active Maintenance Card
        ImprovedSummaryCard(
          icon: Icons.calendar_month,
          title: "Active Maintenance",
          value: _stats != null ? "${_stats!.activeMaintenance}" : "0",
          startColor: const Color(0xFF11998E),
          endColor: const Color(0xFF38EF7D),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MaintenancePeriodsPage(),
              ),
            );
          },
        ),
        
        // Collection Rate Card
        ImprovedSummaryCard(
          icon: Icons.pie_chart,
          title: "Collection Rate",
          value: _calculateCollectionRate(),
          startColor: const Color(0xFFFF8008),
          endColor: const Color(0xFFFFC837),
        ),
      ],
    );
  }
  
  String _calculateCollectionRate() {
    if (_stats == null) return "0%";
    
    final total = _stats!.maintenanceCollected + _stats!.maintenancePending;
    if (total <= 0) return "0%";
    
    final rate = (_stats!.maintenanceCollected / total) * 100;
    return "${rate.toStringAsFixed(1)}%";
  }
}
