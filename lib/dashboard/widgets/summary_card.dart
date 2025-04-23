import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.buttonColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
