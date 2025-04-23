import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:society_management/constants/app_assets.dart';
import 'package:society_management/utility/utility.dart';

// ignore: must_be_immutable
class AppImageViewer extends StatelessWidget {
  const AppImageViewer({
    super.key,
    this.localImage,
    this.networkImage,
    this.height = 100,
    this.width = 100,
    this.localMobileImage,
    this.borderRadius,
  });
  final Uint8List? localImage;
  final File? localMobileImage;
  final String? networkImage;
  final double height;
  final double width;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (localImage != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          localImage!,
          height: height,
          width: width,
          fit: BoxFit.fill,
        ),
      );
    }
    if (localMobileImage != null) {
      return Container(
        height: height,
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 15),
          image: DecorationImage(
            image: FileImage(
              File(localMobileImage?.path ?? ''),
            ),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    if (networkImage != null && networkImage != '') {
      return SizedBox(
        height: height,
        width: width,
        child: Utility.imageLoader(
          url: networkImage!,
          placeholder: AppAssets.appLogo,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(borderRadius ?? 15),
        ),
      );
    }

    return const SizedBox();
  }
}
