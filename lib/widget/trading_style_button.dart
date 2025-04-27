import 'package:flutter/material.dart';

class TradingStyleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? startColor;
  final Color? endColor;
  final double height;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool showChartIcons;
  final Widget? child;
  final bool isLoading;

  const TradingStyleButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.startColor,
    this.endColor,
    this.height = 50,
    this.leadingIcon,
    this.trailingIcon,
    this.showChartIcons = true,
    this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use predefined Material colors
    const defaultStartColor = Colors.indigo; // Deep blue for trading apps
    const defaultEndColor = Colors.teal; // Teal-green for finance

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (endColor ?? defaultEndColor).withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            startColor ?? defaultStartColor,
            endColor ?? defaultEndColor,
          ],
        ),
        border: Border.all(
          color: Colors.white.withAlpha(20),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (child != null) {
      return Center(child: child);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showChartIcons)
          _buildChartIcons()
        else if (leadingIcon != null)
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              leadingIcon,
              color: Colors.white,
              size: 18,
            ),
          ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(
              trailingIcon,
              color: Colors.white,
              size: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChartIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.candlestick_chart,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.show_chart,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }
}
