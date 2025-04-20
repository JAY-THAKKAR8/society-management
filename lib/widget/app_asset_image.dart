import 'package:flutter/material.dart';

class AppAssetImage extends StatelessWidget {
  const AppAssetImage(
    this.assetName, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.color,
  });
  final String assetName;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      color: color,
      assetName,
      height: height,
      width: width,
      fit: fit,
    );
  }
}
