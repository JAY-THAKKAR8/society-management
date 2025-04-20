import 'package:flutter/material.dart';

class NavigationService {
  // Private constructor to prevent direct instantiation
  NavigationService._();

  // Method to navigate to a new screen
  static Future<T?> push<T>({
    required BuildContext context,
    required Widget screen,
  }) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static Future<T?> pushReplacement<T>({
    required BuildContext context,
    required Widget screen,
  }) async {
    return await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>({
    required BuildContext context,
    required Widget screen,
  }) async {
    return await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  // Method to pop the current screen
  static void pop<T>(BuildContext context, [T? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }
}
