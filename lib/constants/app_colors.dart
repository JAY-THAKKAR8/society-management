import 'package:flutter/material.dart';

/// Enhanced color system for the app with support for both light and dark themes
class AppColors {
  // Primary brand colors
  static const Color primaryBlue = Color(0xFF38B6FF);
  static const Color primaryPurple = Color(0xFF6A11CB);
  static const Color primaryTeal = Color(0xFF00B4DB);
  static const Color primaryGreen = Color(0xFF11998E);
  static const Color primaryOrange = Color(0xFFFF8008);
  static const Color primaryPink = Color(0xFFC850C0);
  static const Color primaryRed = Color(0xFFFF416C);

  // Gradient pairs
  static const gradientPurpleBlue = [Color(0xFF3F51B5), Color(0xFF2196F3)]; // Indigo to Blue
  static const gradientRedPink = [Color(0xFFE53935), Color(0xFFFF5252)]; // Red to Light Red
  static const gradientBlueAqua = [Color(0xFF039BE5), Color(0xFF00BCD4)]; // Light Blue to Cyan
  static const gradientGreenTeal = [Color(0xFF43A047), Color(0xFF26A69A)]; // Green to Teal
  static const gradientOrangeYellow = [Color(0xFFFF9800), Color(0xFFFFB300)]; // Orange to Amber
  static const gradientPurplePink = [Color(0xFF7C4DFF), Color(0xFFE040FB)]; // Deep Purple to Purple
  static const gradientBlueIndigo = [Color(0xFF1976D2), Color(0xFF3F51B5)]; // Blue to Indigo

  // Modern Light theme gradients (2024 trend)
  static const gradientLightPrimary = [Color(0xFF6366F1), Color(0xFF4F46E5)]; // Indigo-500 to Indigo-600
  static const gradientLightAccent = [Color(0xFFEC4899), Color(0xFFDB2777)]; // Pink-500 to Pink-600
  static const gradientLightBlue = [Color(0xFF3B82F6), Color(0xFF2563EB)]; // Blue-500 to Blue-600
  static const gradientLightGreen = [Color(0xFF10B981), Color(0xFF059669)]; // Emerald-500 to Emerald-600
  static const gradientLightOrange = [Color(0xFFF97316), Color(0xFFEA580C)]; // Orange-500 to Orange-600
  static const gradientLightPurple = [Color(0xFF8B5CF6), Color(0xFF7C3AED)]; // Violet-500 to Violet-600
  static const gradientLightTeal = [Color(0xFF14B8A6), Color(0xFF0D9488)]; // Teal-500 to Teal-600
  static const gradientLightRed = [Color(0xFFEF4444), Color(0xFFDC2626)]; // Red-500 to Red-600

  // Modern Light theme colors (2024 trend)
  static const Color lightBackground = Color(0xFFF9FAFE); // Soft off-white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightPrimary = Color(0xFF6366F1); // Indigo-500 (Tailwind)
  static const Color lightPrimaryDark = Color(0xFF4F46E5); // Indigo-600 (Tailwind)
  static const Color lightPrimaryLight = Color(0xFFA5B4FC); // Indigo-300 (Tailwind)
  static const Color lightAccent = Color(0xFFEC4899); // Pink-500 (Tailwind)
  static const Color lightAccentDark = Color(0xFFDB2777); // Pink-600 (Tailwind)
  static const Color lightText = Color(0xFF111827); // Gray-900 (Tailwind)
  static const Color lightTextSecondary = Color(0xFF6B7280); // Gray-500 (Tailwind)
  static const Color lightTextTertiary = Color(0xFF9CA3AF); // Gray-400 (Tailwind)
  static const Color lightDivider = Color(0xFFE5E7EB); // Gray-200 (Tailwind)
  static const Color lightCard = Color(0xFFFFFFFF); // White
  static const Color lightCardShadow = Color(0xFFE2E8F0); // Slate-200 (Tailwind)
  static const Color lightError = Color(0xFFEF4444); // Red-500 (Tailwind)
  static const Color lightSuccess = Color(0xFF10B981); // Emerald-500 (Tailwind)
  static const Color lightWarning = Color(0xFFF59E0B); // Amber-500 (Tailwind)
  static const Color lightInfo = Color(0xFF3B82F6); // Blue-500 (Tailwind)

  // Light theme container colors
  static const Color lightContainer = Color(0xFFF1F5F9); // Slate-100 (Tailwind)
  static const Color lightContainerHighlight = Color(0xFFE0E7FF); // Indigo-100 (Tailwind)
  static const Color lightContainerSecondary = Color(0xFFFCE7F3); // Pink-100 (Tailwind)
  static const Color lightContainerSuccess = Color(0xFFD1FAE5); // Emerald-100 (Tailwind)
  static const Color lightContainerWarning = Color(0xFFFEF3C7); // Amber-100 (Tailwind)
  static const Color lightContainerError = Color(0xFFFEE2E2); // Red-100 (Tailwind)
  static const Color lightContainerInfo = Color(0xFFDBEAFE); // Blue-100 (Tailwind)

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = primaryBlue;
  static const Color darkAccent = primaryPurple;
  static const Color darkText = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFFADB5BD);
  static const Color darkDivider = Color(0xFF2D2D2D);
  static const Color darkCard = Color(0xFF252525);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkWarning = Color(0xFFFFCA28);
  static const Color darkInfo = Color(0xFF29B6F6);

  // Common colors
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color red = Color(0xFFFF0000);

  // Legacy colors (for backward compatibility)
  static const Color primary = darkBackground;
  static const Color buttonColor = primaryBlue;
  static const Color lightBlack = Color(0XFF1F2123);
  static const Color greyText = Color(0xFF717D89);
  static const Color yellowColor = Color(0XFFE0EB9F);
  static const Color lightGreen = Color(0XFF89ED8D);
  static const Color lightRed = Color(0XFFFF8088);
  static const Color blurShadow = Color(0XFF434A5C);
}
