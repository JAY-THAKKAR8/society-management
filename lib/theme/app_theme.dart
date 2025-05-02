import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

/// App theme configuration for both light and dark modes
class AppTheme {
  // Modern Light theme (2024 trend)
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.lightPrimary,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.lightPrimaryLight,
          onPrimaryContainer: AppColors.lightPrimaryDark,
          secondary: AppColors.lightAccent,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.lightAccent,
          onSecondaryContainer: AppColors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightText,
          surfaceContainerHighest: AppColors.lightBackground,
          onSurfaceVariant: AppColors.lightTextSecondary,
          error: AppColors.lightError,
          onError: AppColors.white,
          outline: AppColors.lightDivider,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCard,
        dividerColor: AppColors.lightDivider,
        textTheme: _getTextTheme(AppColors.lightText, AppColors.lightTextSecondary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          shadowColor: AppColors.lightCardShadow,
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightPrimary,
            foregroundColor: AppColors.white,
            elevation: 1,
            shadowColor: AppColors.lightPrimary.withAlpha(40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.lightPrimary,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.lightPrimary,
            side: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightDivider, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightDivider, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightError, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightError, width: 2),
          ),
          labelStyle: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(
            color: AppColors.lightTextTertiary,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.lightPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: AppColors.lightPrimary,
          unselectedLabelColor: AppColors.lightTextSecondary,
          indicatorColor: AppColors.lightPrimary,
          dividerColor: AppColors.lightDivider,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: AppColors.lightBackground,
          disabledColor: AppColors.lightDivider,
          selectedColor: AppColors.lightPrimary,
          secondarySelectedColor: AppColors.lightAccent,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          labelStyle: TextStyle(
            color: AppColors.lightText,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          secondaryLabelStyle: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          brightness: Brightness.light,
          shape: StadiumBorder(),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.lightPrimary,
          circularTrackColor: AppColors.lightDivider,
          linearTrackColor: AppColors.lightDivider,
        ),
        cardTheme: CardTheme(
          color: AppColors.lightCard,
          elevation: 1,
          shadowColor: AppColors.lightCardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.lightSurface,
          elevation: 3,
          shadowColor: AppColors.lightCardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            color: AppColors.lightText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
          contentTextStyle: const TextStyle(
            color: AppColors.lightText,
            fontSize: 16,
            letterSpacing: 0.15,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          selectedItemColor: AppColors.lightPrimary,
          unselectedItemColor: AppColors.lightTextSecondary,
          elevation: 4,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.lightPrimary,
          size: 24,
        ),
        primaryIconTheme: const IconThemeData(
          color: AppColors.white,
          size: 24,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.white,
          elevation: 2,
          shape: CircleBorder(),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.lightText,
          contentTextStyle: TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

  // Dark theme
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.white,
          secondary: AppColors.darkAccent,
          onSecondary: AppColors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          error: AppColors.darkError,
          onError: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        dividerColor: AppColors.darkDivider,
        textTheme: _getTextTheme(AppColors.darkText, AppColors.darkTextSecondary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkPrimary,
            foregroundColor: AppColors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkError, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkError, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
          hintStyle: TextStyle(color: AppColors.darkTextSecondary.withAlpha(179)),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: AppColors.darkPrimary,
          unselectedLabelColor: AppColors.darkTextSecondary,
          indicatorColor: AppColors.darkPrimary,
          dividerColor: AppColors.darkDivider,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: AppColors.darkSurface,
          disabledColor: AppColors.darkDivider,
          selectedColor: AppColors.darkPrimary,
          secondarySelectedColor: AppColors.darkAccent,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          labelStyle: TextStyle(color: AppColors.darkText),
          secondaryLabelStyle: TextStyle(color: AppColors.white),
          brightness: Brightness.dark,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.darkPrimary,
          circularTrackColor: AppColors.darkDivider,
          linearTrackColor: AppColors.darkDivider,
        ),
        cardTheme: CardTheme(
          color: AppColors.darkCard,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.darkSurface,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: const TextStyle(
            color: AppColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            color: AppColors.darkText,
            fontSize: 16,
          ),
        ),
      );

  // Common text theme for both light and dark modes
  static TextTheme _getTextTheme(Color primaryTextColor, Color secondaryTextColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: primaryTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: primaryTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: secondaryTextColor,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );
  }
}
