import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode states - simplified to just light and dark
enum ThemeState { light, dark }

/// Theme state management
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themePreferenceKey = 'theme_preference';

  ThemeCubit() : super(ThemeState.dark) {
    _initTheme();
  }

  /// Initialize theme from saved preferences
  Future<void> _initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey);

    if (savedTheme != null) {
      emit(_themeFromString(savedTheme));
    } else {
      // Default to dark theme
      emit(ThemeState.dark);
    }
  }

  /// Change the theme
  Future<void> changeTheme(ThemeState themeState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeState.toString());
    emit(themeState);
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    final newTheme = state == ThemeState.light ? ThemeState.dark : ThemeState.light;
    await changeTheme(newTheme);
  }

  /// Get the current ThemeMode
  ThemeMode get themeMode {
    return state == ThemeState.light ? ThemeMode.light : ThemeMode.dark;
  }

  /// Convert string to ThemeState
  ThemeState _themeFromString(String themeString) {
    return themeString.contains('light') ? ThemeState.light : ThemeState.dark;
  }
}
