import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode states
enum ThemeState { light, dark, system }

/// Events for theme changes
abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final ThemeState themeState;
  ThemeChanged(this.themeState);
}

class ThemeInitialized extends ThemeEvent {}

/// Theme state management
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themePreferenceKey = 'theme_preference';
  
  ThemeCubit() : super(ThemeState.system) {
    _initTheme();
  }

  /// Initialize theme from saved preferences
  Future<void> _initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey);
    
    if (savedTheme != null) {
      emit(_themeFromString(savedTheme));
    } else {
      emit(ThemeState.system);
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
    switch (state) {
      case ThemeState.light:
        return ThemeMode.light;
      case ThemeState.dark:
        return ThemeMode.dark;
      case ThemeState.system:
        return ThemeMode.system;
    }
  }

  /// Convert string to ThemeState
  ThemeState _themeFromString(String themeString) {
    if (themeString.contains('light')) {
      return ThemeState.light;
    } else if (themeString.contains('dark')) {
      return ThemeState.dark;
    } else {
      return ThemeState.system;
    }
  }
}
