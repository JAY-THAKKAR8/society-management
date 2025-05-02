import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/view/app_typography.dart';

class ThemeHelper {
  static TextTheme get lightTextTheme => TextTheme(
        displayLarge: LightAppTypography.displayLarge,
        displayMedium: LightAppTypography.displayMedium,
        displaySmall: LightAppTypography.displaySmall,
        headlineMedium: LightAppTypography.headlineMedium,
        headlineSmall: LightAppTypography.headlineSmall,
        titleLarge: LightAppTypography.titleLarge,
        titleMedium: LightAppTypography.titleMedium,
        titleSmall: LightAppTypography.titleSmall,
        bodyLarge: LightAppTypography.bodyLarge,
        bodyMedium: LightAppTypography.bodyMedium,
        bodySmall: LightAppTypography.bodySmall,
        labelLarge: LightAppTypography.labelLarge,
        labelMedium: LightAppTypography.labelMedium,
        labelSmall: LightAppTypography.labelSmall,
      );

  static InputDecorationTheme get inputDecorationLight {
    final commonBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.lightDivider));

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightContainer,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      hintStyle: LightAppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      errorStyle: LightAppTypography.bodySmall.copyWith(color: AppColors.lightError),
      counterStyle: LightAppTypography.bodyMedium.copyWith(color: AppColors.lightText),
      errorMaxLines: 2,
      enabledBorder: commonBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
      ),
      disabledBorder: commonBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.lightError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.lightError, width: 1.5),
      ),
      border: commonBorder,
    );
  }

  static ElevatedButtonThemeData get elevatedButtonLight {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        minimumSize: const Size(double.infinity, 0),
        textStyle: LightAppTypography.bodyLarge.copyWith(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static DividerThemeData get dividerThemeLight {
    return const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
    );
  }

  static ProgressIndicatorThemeData get progressIndicatorThemeLight {
    return const ProgressIndicatorThemeData(
      color: AppColors.lightPrimary,
      circularTrackColor: AppColors.lightDivider,
    );
  }

  static ChipThemeData get chipThemeLight {
    return ChipThemeData(
      backgroundColor: AppColors.lightContainer,
      selectedColor: AppColors.lightPrimary,
      labelStyle: lightTextTheme.bodyMedium?.copyWith(
        color: AppColors.lightText,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: lightTextTheme.bodyMedium?.copyWith(
        color: AppColors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static AppBarTheme get appBarThemeLight {
    return const AppBarTheme(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: AppColors.white,
      elevation: 0,
    );
  }

  static TabBarTheme get tabBarThemeLight {
    return TabBarTheme(
      labelPadding: EdgeInsets.zero,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: AppColors.lightPrimary,
      ),
      labelStyle: lightTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      unselectedLabelStyle: lightTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
      ),
    );
  }
}
