import 'package:flutter/material.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/maintenance/view/improved_active_maintenance_stats_page.dart';
import 'package:society_management/reports/view/member_report_page.dart';
import 'package:society_management/reports/view/payment_report_page.dart';
import 'package:society_management/reports/view/society_overview_report_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/theme_aware_card.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Admin Reports Dashboard',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(context),
              const SizedBox(height: 24),

              // Report Types Section
              _buildReportTypesSection(context),
              const SizedBox(height: 24),

              // Line-wise Reports Section
              _buildLineReportsSection(context),
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
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF4F46E5),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Society Reports Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generate comprehensive reports for all lines and members',
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

  Widget _buildReportTypesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Categories',
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
          childAspectRatio: 0.77,
          children: [
            _buildReportTypeCard(
              context,
              icon: Icons.payment,
              title: 'Payment Reports',
              description: 'Financial tracking & collection analysis',
              gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
              onTap: () => _showLineSelectionDialog(context, 'payment'),
            ),
            _buildReportTypeCard(
              context,
              icon: Icons.people,
              title: 'Member Reports',
              description: 'Member directory & contact information',
              gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
              onTap: () => _showLineSelectionDialog(context, 'member'),
            ),
            _buildReportTypeCard(
              context,
              icon: Icons.bar_chart,
              title: 'Statistics Reports',
              description: 'Performance metrics & analytics',
              gradientColors: [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
              onTap: () => _showLineSelectionDialog(context, 'statistics'),
            ),
            _buildReportTypeCard(
              context,
              icon: Icons.dashboard,
              title: 'Society Overview',
              description: 'Complete society performance summary',
              gradientColors: [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
              onTap: () => _generateSocietyOverviewReport(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return ThemeAwareCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
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

  Widget _buildLineReportsSection(BuildContext context) {
    final lines = [
      AppConstants.firstLine,
      AppConstants.secondLine,
      AppConstants.thirdLine,
      AppConstants.fourthLine,
      AppConstants.fifthLine,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line-wise Quick Reports',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...lines.map((line) => _buildLineCard(context, line)),
      ],
    );
  }

  Widget _buildLineCard(BuildContext context, String lineNumber) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ThemeAwareCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                ),
              ),
              const SizedBox(width: 16),
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
                      'Generate reports for this line',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _navigateToPaymentReport(context, lineNumber),
                    icon: const Icon(Icons.payment),
                    tooltip: 'Payment Report',
                  ),
                  IconButton(
                    onPressed: () => _navigateToMemberReport(context, lineNumber),
                    icon: const Icon(Icons.people),
                    tooltip: 'Member Report',
                  ),
                  IconButton(
                    onPressed: () => _navigateToStatistics(context),
                    icon: const Icon(Icons.bar_chart),
                    tooltip: 'Statistics',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLineSelectionDialog(BuildContext context, String reportType) {
    final lines = [
      AppConstants.firstLine,
      AppConstants.secondLine,
      AppConstants.thirdLine,
      AppConstants.fourthLine,
      AppConstants.fifthLine,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Line for ${reportType.toUpperCase()} Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: lines
              .map((line) => ListTile(
                    title: Text(line.toUpperCase().replaceAll('_', ' ')),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToReport(context, reportType, line);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToReport(BuildContext context, String reportType, String lineNumber) {
    switch (reportType) {
      case 'payment':
        _navigateToPaymentReport(context, lineNumber);
        break;
      case 'member':
        _navigateToMemberReport(context, lineNumber);
        break;
      case 'statistics':
        _navigateToStatistics(context);
        break;
    }
  }

  void _navigateToPaymentReport(BuildContext context, String lineNumber) {
    context.push(PaymentReportPage(lineNumber: lineNumber));
  }

  void _navigateToMemberReport(BuildContext context, String lineNumber) {
    context.push(MemberReportPage(lineNumber: lineNumber));
  }

  void _navigateToStatistics(BuildContext context) {
    context.push(const ImprovedActiveMaintenanceStatsPage());
  }

  void _generateSocietyOverviewReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SocietyOverviewReportPage(),
      ),
    );
  }
}
