import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppSvgImage extends StatelessWidget {
  const AppSvgImage(
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
    return SvgPicture.asset(
      assetName,
      height: height,
      width: width,
      fit: fit,
      colorFilter: color != null ? ColorFilter.mode(color ?? Colors.transparent, BlendMode.srcIn) : null,
    );
  }
}
