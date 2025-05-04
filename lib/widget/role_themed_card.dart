import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/theme/theme_utils.dart';

/// A card widget that automatically adapts its styling based on the user's role
/// and the current theme settings
class RoleThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final String? userRole;
  final bool useGradient;
  final double? width;
  final double? height;

  const RoleThemedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius,
    this.elevation = 1,
    this.onTap,
    this.userRole,
    this.useGradient = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors based on role
    final roleColors = _getRoleColors(context);
    final isDarkMode = ThemeUtils.isDarkMode(context);
    
    // Create the card content
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: useGradient 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  roleColors.primary.withOpacity(isDarkMode ? 0.8 : 0.1),
                  roleColors.secondary.withOpacity(isDarkMode ? 0.6 : 0.05),
                ],
              )
            : null,
        color: useGradient 
            ? null 
            : ThemeUtils.getContainerColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: roleColors.primary.withOpacity(isDarkMode ? 0.3 : 0.1),
          width: 1,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: roleColors.primary.withOpacity(0.1),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    // Make the card tappable if onTap is provided
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  /// Get colors based on user role
  RoleColors _getRoleColors(BuildContext context) {
    switch (userRole) {
      case AppConstants.admin:
        return RoleColors(
          primary: AppColors.primaryBlue,
          secondary: AppColors.primaryPurple,
          accent: AppColors.primaryTeal,
        );
      case AppConstants.lineLead:
        return RoleColors(
          primary: AppColors.primaryGreen,
          secondary: AppColors.primaryTeal,
          accent: AppColors.primaryBlue,
        );
      case AppConstants.lineHeadAndMember:
        return RoleColors(
          primary: AppColors.primaryOrange,
          secondary: AppColors.primaryGreen,
          accent: AppColors.primaryTeal,
        );
      case AppConstants.lineMember:
        return RoleColors(
          primary: AppColors.primaryPurple,
          secondary: AppColors.primaryPink,
          accent: AppColors.primaryBlue,
        );
      default:
        // Default colors if role is not specified
        return RoleColors(
          primary: Theme.of(context).colorScheme.primary,
          secondary: Theme.of(context).colorScheme.secondary,
          accent: Theme.of(context).colorScheme.tertiary,
        );
    }
  }
}

/// Helper class to store role-specific colors
class RoleColors {
  final Color primary;
  final Color secondary;
  final Color accent;

  RoleColors({
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

/// A summary card with role-specific styling
class RoleThemedSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;
  final VoidCallback? onTap;
  final String? userRole;

  const RoleThemedSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
    this.onTap,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final roleColors = _getRoleColors(context);
    final effectiveIconColor = iconColor ?? roleColors.primary;
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return RoleThemedCard(
      userRole: userRole,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: effectiveIconColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// Get colors based on user role
  RoleColors _getRoleColors(BuildContext context) {
    switch (userRole) {
      case AppConstants.admin:
        return RoleColors(
          primary: AppColors.primaryBlue,
          secondary: AppColors.primaryPurple,
          accent: AppColors.primaryTeal,
        );
      case AppConstants.lineLead:
        return RoleColors(
          primary: AppColors.primaryGreen,
          secondary: AppColors.primaryTeal,
          accent: AppColors.primaryBlue,
        );
      case AppConstants.lineHeadAndMember:
        return RoleColors(
          primary: AppColors.primaryOrange,
          secondary: AppColors.primaryGreen,
          accent: AppColors.primaryTeal,
        );
      case AppConstants.lineMember:
        return RoleColors(
          primary: AppColors.primaryPurple,
          secondary: AppColors.primaryPink,
          accent: AppColors.primaryBlue,
        );
      default:
        // Default colors if role is not specified
        return RoleColors(
          primary: Theme.of(context).colorScheme.primary,
          secondary: Theme.of(context).colorScheme.secondary,
          accent: Theme.of(context).colorScheme.tertiary,
        );
    }
  }
}
