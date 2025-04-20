import 'package:flutter/material.dart';
import 'package:society_management/dashboard/widgets/quick_action_button.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, this.onAddUser, this.onAddExpense, this.onBroadcastNotice, this.onViewReport});
  final void Function()? onAddUser;
  final void Function()? onAddExpense;
  final void Function()? onBroadcastNotice;
  final void Function()? onViewReport;

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
              icon: Icons.person_add,
              label: "Add User",
              onPressed: onAddUser,
            ),
            QuickActionButton(
              icon: Icons.attach_money,
              label: "Add Expense",
              onPressed: onAddExpense,
            ),
            QuickActionButton(
              icon: Icons.campaign,
              label: "Broadcast Notice",
              onPressed: onBroadcastNotice,
            ),
            QuickActionButton(
              icon: Icons.bar_chart,
              label: "View Report",
              onPressed: onViewReport,
            ),
          ],
        ),
      ],
    );
  }
}
