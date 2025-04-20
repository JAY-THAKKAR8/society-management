import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

class LightAppTypography {
  static const _fontFamily = 'SFProDisplay';

  static const _style = TextStyle(fontFamily: _fontFamily, color: AppColors.white);

  static TextStyle displayLarge = _style.copyWith(
    fontSize: 96,
    fontWeight: FontWeight.w600, // Semibold
    letterSpacing: -1.5,
  );

  static TextStyle displayMedium = _style.copyWith(
    fontSize: 60,
    fontWeight: FontWeight.w600, // Semibold
    letterSpacing: -0.5,
  );

  static TextStyle displaySmall = _style.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w400, // Regular
  );

  static TextStyle headlineMedium = _style.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 0.25,
  );

  static TextStyle headlineSmall = _style.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700, // Regular
  );

  static TextStyle titleLarge = _style.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 0.15,
  );

  static TextStyle titleMedium = _style.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Regular
    letterSpacing: 0.15,
  );

  static TextStyle titleSmall = _style.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 0.1,
  );

  static TextStyle bodyLarge = _style.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700, // Regular
    letterSpacing: 1,
  );

  static TextStyle bodyMedium = _style.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 1,
    height: 1.6,
  );

  static TextStyle bodySmall = _style.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 0.4,
  );

  static TextStyle labelLarge = _style.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 1.25,
  );

  static TextStyle labelMedium = _style.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = _style.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 0.5,
  );
}
