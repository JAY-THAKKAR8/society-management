import 'package:flutter/material.dart';

extension ColorsExtensions on Color {
  Color withOpacity2(double opacity) {
    return withOpacity(opacity); // ✅ Correct method
  }
}
