import 'package:flutter/material.dart';

extension ColorsExtnetions on Color {
  Color withOpacity2(double opacity) {
    return withValues(alpha: opacity);
  }
}
