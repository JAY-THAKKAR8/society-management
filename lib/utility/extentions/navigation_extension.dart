import 'package:flutter/material.dart';
import 'package:society_management/constants/navigation_service.dart';

extension NavigationExtension on BuildContext {
  Future<T?> push<T>(Widget screen) => NavigationService.push<T>(
        context: this,
        screen: screen,
      );

  Future<T?> pushAndRemoveUntil<T>(Widget screen) => NavigationService.pushAndRemoveUntil<T>(
        context: this,
        screen: screen,
      );

  Future<T?> pushReplacement<T>(Widget screen) => NavigationService.pushReplacement<T>(
        context: this,
        screen: screen,
      );

  void pop<T>([T? result]) => NavigationService.pop(this, result);
}
