import 'package:flutter/material.dart';

/// A reusable card widget with customizable properties
class CommonCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double elevation;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Border? border;

  const CommonCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.elevation = 2,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.onTap,
    this.width,
    this.height,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
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
