import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

/// Utility functions for theme-related operations
class ThemeUtils {
  /// Check if the current theme is dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get the appropriate container color based on the current theme
  static Color getContainerColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkCard : AppColors.lightContainer;
  }

  /// Get the appropriate card color based on the current theme
  static Color getCardColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkCard : AppColors.lightCard;
  }

  /// Get the appropriate dialog color based on the current theme
  static Color getDialogColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkSurface : AppColors.lightSurface;
  }

  /// Get the appropriate border color based on the current theme
  static Color getBorderColor(BuildContext context, {double opacity = 1.0}) {
    return isDarkMode(context) ? Colors.white.withOpacity(0.1 * opacity) : AppColors.lightDivider.withOpacity(opacity);
  }

  /// Get the appropriate text color based on the current theme
  static Color getTextColor(BuildContext context, {bool secondary = false}) {
    return isDarkMode(context)
        ? (secondary ? AppColors.darkTextSecondary : AppColors.darkText)
        : (secondary ? AppColors.lightTextSecondary : AppColors.lightText);
  }

  /// Get the appropriate highlight color based on the current theme and color
  static Color getHighlightColor(BuildContext context, Color color, {double opacity = 0.2}) {
    return color.withOpacity(isDarkMode(context) ? opacity : opacity * 1.5);
  }

  /// Get the appropriate input field color based on the current theme
  static Color getInputFieldColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkSurface : AppColors.lightContainer;
  }

  /// Get the appropriate dropdown color based on the current theme
  static Color getDropdownColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkSurface : AppColors.lightContainer;
  }

  /// Get the appropriate primary color based on the current theme
  static Color getPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkPrimary : AppColors.lightPrimary;
  }

  /// Get the appropriate accent color based on the current theme
  static Color getAccentColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkAccent : AppColors.lightAccent;
  }

  /// Get the appropriate background color based on the current theme
  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkBackground : AppColors.lightBackground;
  }

  /// Get the appropriate surface color based on the current theme
  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkSurface : AppColors.lightSurface;
  }

  /// Get the appropriate divider color based on the current theme
  static Color getDividerColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkDivider : AppColors.lightDivider;
  }

  /// Get the appropriate error color based on the current theme
  static Color getErrorColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkError : AppColors.lightError;
  }

  /// Get the appropriate success color based on the current theme
  static Color getSuccessColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkSuccess : AppColors.lightSuccess;
  }

  /// Get the appropriate warning color based on the current theme
  static Color getWarningColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkWarning : AppColors.lightWarning;
  }

  /// Get the appropriate info color based on the current theme
  static Color getInfoColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.darkInfo : AppColors.lightInfo;
  }
}
