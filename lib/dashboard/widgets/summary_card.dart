import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/theme_utils.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? ThemeUtils.getPrimaryColor(context);
    final effectiveIconBgColor =
        iconBackgroundColor ?? ThemeUtils.getHighlightColor(context, effectiveIconColor, opacity: 0.15);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getContainerColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeUtils.getBorderColor(context)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 28, color: effectiveIconColor),
              ),
            ),
            const SizedBox(height: 12),
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
