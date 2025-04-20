import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/view/app_typography.dart';
import 'package:society_management/utility/extentions/colors_extnetions.dart';

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
        borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.white.withOpacity2(0.2)));

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightBlack,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      hintStyle: LightAppTypography.bodyMedium.copyWith(color: AppColors.greyText),
      errorStyle: LightAppTypography.bodySmall.copyWith(color: AppColors.red),
      counterStyle: LightAppTypography.bodyMedium,
      errorMaxLines: 2,
      enabledBorder: commonBorder,
      focusedBorder: commonBorder,
      disabledBorder: commonBorder,
      errorBorder: commonBorder,
      focusedErrorBorder: commonBorder,
      border: commonBorder,
    );
  }

  static ElevatedButtonThemeData get elevatedButtonLight {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        minimumSize: const Size(double.infinity, 0),
        textStyle: LightAppTypography.bodyLarge.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static DividerThemeData get dividerThemeLight {
    return const DividerThemeData(
      color: AppColors.greyText,
      thickness: 1,
    );
  }

  static ProgressIndicatorThemeData get progressIndicatorThemeLight {
    return const ProgressIndicatorThemeData(
      color: AppColors.primary,
      circularTrackColor: Colors.transparent,
    );
  }

  static ChipThemeData get chipThemeLight {
    return ChipThemeData(
      backgroundColor: AppColors.primary,
      selectedColor: AppColors.primary,
      labelStyle: lightTextTheme.bodyMedium?.copyWith(
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
      backgroundColor: AppColors.primary,
      elevation: 0,
    );
  }

  static TabBarTheme get tabBarThemeLight {
    return TabBarTheme(
      labelPadding: EdgeInsets.zero,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: AppColors.primary,
      ),
      labelStyle: lightTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      unselectedLabelStyle: lightTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
