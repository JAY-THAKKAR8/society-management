import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

/// A reusable gradient button with customizable colors and content
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final Color textColor;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final IconData? icon;
  final double elevation;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradientColors = const [AppColors.primaryBlue, AppColors.primaryTeal],
    this.textColor = Colors.white,
    this.height = 50,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.borderRadius,
    this.isLoading = false,
    this.icon,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onPressed == null 
              ? gradientColors.map((color) => color.withOpacity(0.5)).toList() 
              : gradientColors,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: onPressed == null ? [] : [
          BoxShadow(
            color: gradientColors.last.withAlpha(40),
            blurRadius: elevation * 4,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: onPressed == null ? textColor.withOpacity(0.5) : textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (onPressed == null || isLoading) {
      return buttonContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: buttonContent,
      ),
    );
  }
}
