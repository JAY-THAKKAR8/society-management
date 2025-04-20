import 'package:flutter/material.dart';
import 'package:society_management/dashboard/widgets/recent_activity_item.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Sample activity data
    final List<String> activities = [
      "✅ Payment received from John (₹1,200)",
      "📢 Notice sent to all Line Heads",
      "🧾 New user added: Ramesh (Line Member)",
      "⚠ Complaint logged by Line 3",
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activity",
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...activities.map(
          (activity) => RecentActivityItem(activity: activity),
        ),
      ],
    );
  }
}
