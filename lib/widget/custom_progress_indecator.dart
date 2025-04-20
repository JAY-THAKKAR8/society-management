import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

class CustomProgressIndecator extends StatelessWidget {
  const CustomProgressIndecator({
    super.key,
    this.color,
    this.strokeWidth = 4.0,
    this.value,
  });
  final Color? color;
  final double strokeWidth;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      color: color ?? AppColors.white,
      strokeWidth: strokeWidth,
      value: value,
    );
  }
}
