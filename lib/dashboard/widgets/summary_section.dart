import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/dashboard/widgets/summary_card.dart';

class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dashboard Summary",
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: SummaryCard(icon: Icons.group, title: "Total Members", value: "120")),
            Gap(16),
            Expanded(child: SummaryCard(icon: Icons.monetization_on, title: "Pending Dues", value: "₹24,000")),
          ],
        ),
        const Gap(16),
        const Row(
          children: [
            Expanded(child: SummaryCard(icon: Icons.inventory, title: "Total Expenses", value: "₹89,000")),
            Gap(16),
            Expanded(child: SummaryCard(icon: Icons.report_problem, title: "Open Complaints", value: "8")),
          ],
        ),
      ],
    );
  }
}
