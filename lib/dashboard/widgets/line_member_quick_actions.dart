import 'package:flutter/material.dart';
import 'package:society_management/dashboard/widgets/quick_action_button.dart';
import 'package:society_management/events/view/events_list_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';

class LineMemberQuickActions extends StatelessWidget {
  const LineMemberQuickActions({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            QuickActionButton(
              icon: Icons.report_problem,
              label: "Add Complaint",
              onPressed: onAddComplaint,
            ),
            QuickActionButton(
              icon: Icons.list_alt,
              label: "My Complaints",
              onPressed: onViewComplaints,
            ),
            QuickActionButton(
              icon: Icons.monetization_on,
              label: "Maintenance Status",
              onPressed: onViewMaintenanceStatus,
            ),
            QuickActionButton(
              icon: Icons.event,
              label: "Society Events",
              onPressed: () {
                context.push(const EventsListPage());
              },
            ),
          ],
        ),
      ],
    );
  }
}
