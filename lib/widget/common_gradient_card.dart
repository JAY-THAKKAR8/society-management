import 'package:flutter/material.dart';

/// A reusable gradient card widget with customizable colors and content
class CommonGradientCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double elevation;

  const CommonGradientCard({
    super.key,
    required this.gradientColors,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderRadius,
    this.onTap,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withAlpha(40),
            blurRadius: elevation * 4,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
