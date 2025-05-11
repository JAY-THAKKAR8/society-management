import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/events/view/events_list_page.dart';
import 'package:society_management/theme/theme_utils.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class ImprovedLineMemberQuickActions extends StatelessWidget {
  const ImprovedLineMemberQuickActions({
    super.key,
    this.onAddComplaint,
    this.onViewComplaints,
    this.onViewMaintenanceStatus,
  });

  final void Function()? onAddComplaint;
  final void Function()? onViewComplaints;
  final void Function()? onViewMaintenanceStatus;

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
                    ? const Color(0x33C850C0) // 20% opacity of primaryPink
                    : const Color(0x1AEC4899), // 10% opacity of lightAccent
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Member Tools",
                style: TextStyle(
                  color: isDarkMode ? AppColors.primaryPink : AppColors.lightAccent,
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
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildQuickActionCard(
              context,
              icon: Icons.report_problem,
              title: "Add Complaint",
              description: "Submit a new complaint",
              gradientColors: isDarkMode
                  ? [const Color(0xFFE53935), const Color(0xFFFF5252)] // gradientRedPink
                  : [const Color(0xFFEF4444), const Color(0xFFF87171)], // lightError shades
              onTap: onAddComplaint,
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.list_alt,
              title: "My Complaints",
              description: "View your complaint history",
              gradientColors: isDarkMode
                  ? [const Color(0xFF7C4DFF), const Color(0xFFE040FB)] // gradientPurplePink
                  : [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // lightPurple shades
              onTap: onViewComplaints,
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.monetization_on,
              title: "Maintenance Status",
              description: "Check your payment status",
              gradientColors: isDarkMode
                  ? [const Color(0xFF43A047), const Color(0xFF26A69A)] // gradientGreenTeal
                  : [const Color(0xFF10B981), const Color(0xFF34D399)], // lightGreen shades
              onTap: onViewMaintenanceStatus,
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.event,
              title: "Society Events",
              description: "View upcoming events",
              gradientColors: isDarkMode
                  ? [const Color(0xFF039BE5), const Color(0xFF00BCD4)] // gradientBlueAqua
                  : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // lightBlue shades
              onTap: () {
                context.push(const EventsListPage());
              },
            ),
          ],
        ),
      ],
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
