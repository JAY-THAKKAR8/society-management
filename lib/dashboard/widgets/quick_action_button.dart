import 'package:flutter/material.dart';
import 'package:society_management/widget/trading_style_button.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TradingStyleButton(
      text: label,
      onPressed: onPressed ?? () {},
      leadingIcon: icon,
      showChartIcons: false,
    );
  }
}
