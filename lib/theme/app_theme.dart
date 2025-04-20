import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/view/theme_helper.dart';

sealed class AppTheme {
  static ThemeData get light => ThemeData(
        scaffoldBackgroundColor: AppColors.primary,
        brightness: Brightness.dark,
        textTheme: ThemeHelper.lightTextTheme,
        inputDecorationTheme: ThemeHelper.inputDecorationLight,
        elevatedButtonTheme: ThemeHelper.elevatedButtonLight,
        useMaterial3: false,
        dividerTheme: ThemeHelper.dividerThemeLight,
        progressIndicatorTheme: ThemeHelper.progressIndicatorThemeLight,
        chipTheme: ThemeHelper.chipThemeLight,
        appBarTheme: ThemeHelper.appBarThemeLight,
        tabBarTheme: ThemeHelper.tabBarThemeLight,
      );
}
