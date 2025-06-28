import 'package:flutter/material.dart';
import 'package:society_management/chat/view/chat_page.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/maintenance/view/improved_active_maintenance_stats_page.dart';
import 'package:society_management/maintenance/view/line_member_maintenance_page.dart';
import 'package:society_management/maintenance/view/maintenance_periods_page.dart';
import 'package:society_management/meetings/view/meeting_dashboard_page.dart';
import 'package:society_management/reports/view/member_report_page.dart';
import 'package:society_management/reports/view/payment_report_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/users/view/line_head_users_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class ImprovedLineHeadQuickActions extends StatelessWidget {
  final String? lineNumber;
  final VoidCallback? onActionComplete;

  const ImprovedLineHeadQuickActions({
    super.key,
    this.lineNumber,
    this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Quick Actions",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0x3311998E) // 20% opacity of primaryGreen
                    : const Color(0x1A10B981), // 10% opacity of lightGreen
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Line Head Tools",
                style: TextStyle(
                  color: isDarkMode ? AppColors.primaryGreen : AppColors.lightGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // AI Assistant - Featured first for Line Heads
            _buildQuickActionCard(
              context,
              icon: Icons.smart_toy,
              title: "AI Assistant",
              description: "Line collection insights",
              gradientColors: isDarkMode
                  ? [const Color(0xFFE91E63), const Color(0xFFFF5722)] // gradientPinkRed
                  : [const Color(0xFFEC4899), const Color(0xFFF97316)], // lightPink to orange
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
                onActionComplete?.call();
              },
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.group,
              title: "View Line Members",
              description: "Manage your line members",
              gradientColors: isDarkMode
                  ? [const Color(0xFF3F51B5), const Color(0xFF2196F3)] // gradientPurpleBlue
                  : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // lightBlue shades
              onTap: () async {
                await context.push(const LineHeadUsersPage());
                onActionComplete?.call();
              },
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.payments,
              title: "Collect Maintenance",
              description: "Record member payments",
              gradientColors: isDarkMode
                  ? [const Color(0xFF43A047), const Color(0xFF26A69A)] // gradientGreenTeal
                  : [const Color(0xFF10B981), const Color(0xFF34D399)], // lightGreen shades
              onTap: () async {
                await context.push(LineMemberMaintenancePage(lineNumber: lineNumber));
                onActionComplete?.call();
              },
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.calendar_month,
              title: "Maintenance Periods",
              description: "View active periods",
              gradientColors: isDarkMode
                  ? [const Color(0xFFFF9800), const Color(0xFFFFB300)] // gradientOrangeYellow
                  : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // lightAmber shades
              onTap: () async {
                await context.push(const MaintenancePeriodsPage());
                onActionComplete?.call();
              },
            ),

            _buildQuickActionCard(
              context,
              icon: Icons.groups,
              title: "Line Meetings",
              description: "Manage line meetings",
              gradientColors: isDarkMode
                  ? [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)] // gradientRedYellow
                  : [const Color(0xFFEF4444), const Color(0xFFFBBF24)], // lightRed to yellow
              onTap: () async {
                await context.push(const MeetingDashboardPage());
                onActionComplete?.call();
              },
            ),

            _buildQuickActionCard(
              context,
              icon: Icons.summarize,
              title: "Generate Reports",
              description: "Payment & member reports",
              gradientColors: isDarkMode
                  ? [const Color(0xFF7C4DFF), const Color(0xFFE040FB)] // gradientPurplePink
                  : [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // lightPurple shades
              onTap: () {
                _showReportOptionsDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showReportOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Reports'),
        content: const Text('Choose the type of report you want to generate:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Payment Report
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentReportPage(lineNumber: lineNumber ?? ''),
                ),
              );
              onActionComplete?.call();
            },
            child: const Text('Payment Report'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Member Report
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberReportPage(lineNumber: lineNumber ?? ''),
                ),
              );
              onActionComplete?.call();
            },
            child: const Text('Member Report'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Line Statistics
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImprovedActiveMaintenanceStatsPage(),
                ),
              );
              onActionComplete?.call();
            },
            child: const Text('Line Statistics'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required VoidCallback? onTap,
  }) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onTap == null
                  ? [
                      gradientColors[0].withAlpha(150),
                      gradientColors[1].withAlpha(150),
                    ]
                  : gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[1].withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isDarkMode ? 40 : 60),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
