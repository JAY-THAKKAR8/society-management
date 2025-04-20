import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

class RecentActivityItem extends StatelessWidget {
  final String activity;
  
  const RecentActivityItem({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.notifications, 
          color: AppColors.buttonColor,
        ),
        title: Text(
          activity,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
