import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:society_management/utility/utility.dart';

class ScreenshotUtility {
  static final GlobalKey _screenshotKey = GlobalKey();

  static GlobalKey get screenshotKey => _screenshotKey;

  static Future<void> captureAndShareScreenshot(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Find the render object
      final RenderRepaintBoundary boundary = _screenshotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        Utility.toast(message: 'Failed to capture screenshot');
        return;
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final File file = File('$tempPath/screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Share the screenshot
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'KDV Management Screenshot',
      );
      
      Utility.toast(message: 'Screenshot captured and shared');
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      Utility.toast(message: 'Error capturing screenshot: $e');
    }
  }
}
