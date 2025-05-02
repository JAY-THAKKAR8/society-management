import 'package:flutter/material.dart';
import 'package:society_management/theme/theme_utils.dart';

/// A card widget that automatically uses the appropriate colors based on the current theme
class ThemeAwareCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final Border? border;
  final Color? borderColor;
  final double? width;
  final double? height;
  final bool useContainerColor;
  final Color? customColor;

  const ThemeAwareCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius,
    this.elevation = 1,
    this.onTap,
    this.border,
    this.borderColor,
    this.width,
    this.height,
    this.useContainerColor = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the appropriate color based on theme
    final color = customColor ?? 
        (useContainerColor 
            ? ThemeUtils.getContainerColor(context) 
            : ThemeUtils.getCardColor(context));
    
    // Create border if specified
    final effectiveBorder = border ?? 
        (borderColor != null 
            ? Border.all(color: borderColor!) 
            : null);
    
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: effectiveBorder,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

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
}

/// A card with a colored border based on status or role
class StatusCard extends ThemeAwareCard {
  StatusCard({
    required Widget child,
    required BuildContext context,
    Color statusColor = Colors.blue,
    bool isActive = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
    BorderRadius? borderRadius,
    double elevation = 1,
    VoidCallback? onTap,
    double? width,
    double? height,
    bool useContainerColor = true,
  }) : super(
          child: child,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          elevation: elevation,
          onTap: onTap,
          width: width,
          height: height,
          useContainerColor: useContainerColor,
          border: Border.all(
            color: isActive
                ? statusColor.withOpacity(ThemeUtils.isDarkMode(context) ? 0.4 : 0.6)
                : ThemeUtils.getBorderColor(context),
            width: isActive ? 1.5 : 1.0,
          ),
        );
}
