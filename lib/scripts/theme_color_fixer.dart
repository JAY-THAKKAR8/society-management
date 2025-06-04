import 'dart:io';

import 'package:path/path.dart' as path;

/// A script to find and replace hard-coded dark colors in the codebase
///
/// Usage:
/// 1. Run this script from the root of the project:
///    dart lib/scripts/theme_color_fixer.dart
///
/// This script will:
/// 1. Find all Dart files in the lib directory
/// 2. Look for instances of AppColors.lightBlack used in Card or Container widgets
/// 3. Replace them with ThemeUtils.getContainerColor(context) or ThemeUtils.getCardColor(context)
/// 4. Add the necessary import if it's missing
void main() async {
  final libDir = Directory('lib');
  final dartFiles = await _findDartFiles(libDir);

  int filesModified = 0;
  int replacementsCount = 0;

  for (final file in dartFiles) {
    final content = await File(file).readAsString();

    // Skip files that don't contain AppColors.lightBlack
    if (!content.contains('AppColors.lightBlack')) {
      continue;
    }

    // Check if the file already imports ThemeUtils
    final hasThemeUtilsImport = content.contains("import 'package:society_management/theme/theme_utils.dart';");

    // Create a modified version of the content
    var modifiedContent = content;

    // Replace Card color: AppColors.lightBlack with ThemeUtils.getCardColor(context)
    final cardRegex = RegExp(r'Card\(\s*(?:[^,]*,\s*)*color:\s*AppColors\.lightBlack');
    if (cardRegex.hasMatch(modifiedContent)) {
      modifiedContent = modifiedContent.replaceAllMapped(
        cardRegex,
        (match) => match[0]!.replaceFirst('AppColors.lightBlack', 'ThemeUtils.getCardColor(context)'),
      );
      replacementsCount++;
    }

    // Replace Container color: AppColors.lightBlack with ThemeUtils.getContainerColor(context)
    final containerRegex = RegExp(r'Container\(\s*(?:[^,]*,\s*)*color:\s*AppColors\.lightBlack');
    if (containerRegex.hasMatch(modifiedContent)) {
      modifiedContent = modifiedContent.replaceAllMapped(
        containerRegex,
        (match) => match[0]!.replaceFirst('AppColors.lightBlack', 'ThemeUtils.getContainerColor(context)'),
      );
      replacementsCount++;
    }

    // Replace decoration: BoxDecoration(color: AppColors.lightBlack with ThemeUtils.getContainerColor(context)
    final boxDecorationRegex = RegExp(r'decoration:\s*BoxDecoration\(\s*(?:[^,]*,\s*)*color:\s*AppColors\.lightBlack');
    if (boxDecorationRegex.hasMatch(modifiedContent)) {
      modifiedContent = modifiedContent.replaceAllMapped(
        boxDecorationRegex,
        (match) => match[0]!.replaceFirst('AppColors.lightBlack', 'ThemeUtils.getContainerColor(context)'),
      );
      replacementsCount++;
    }

    // Replace AlertDialog backgroundColor: AppColors.lightBlack with ThemeUtils.getDialogColor(context)
    final alertDialogRegex = RegExp(r'AlertDialog\(\s*(?:[^,]*,\s*)*backgroundColor:\s*AppColors\.lightBlack');
    if (alertDialogRegex.hasMatch(modifiedContent)) {
      modifiedContent = modifiedContent.replaceAllMapped(
        alertDialogRegex,
        (match) => match[0]!.replaceFirst('AppColors.lightBlack', 'ThemeUtils.getDialogColor(context)'),
      );
      replacementsCount++;
    }

    // Add the import if needed and there were replacements
    if (!hasThemeUtilsImport && content != modifiedContent) {
      // Find the last import statement
      final importRegex = RegExp(r"import\s+'[^']+';");
      final matches = importRegex.allMatches(modifiedContent).toList();

      if (matches.isNotEmpty) {
        final lastImport = matches.last;
        final insertPosition = lastImport.end;

        modifiedContent =
            "${modifiedContent.substring(0, insertPosition)}\nimport 'package:society_management/theme/theme_utils.dart';${modifiedContent.substring(insertPosition)}";
      }
    }

    // Write the modified content back to the file if changes were made
    if (content != modifiedContent) {
      await File(file).writeAsString(modifiedContent);
      filesModified++;
      print('Updated ${path.basename(file)}');
    }
  }

  print('Done! Modified $filesModified files with $replacementsCount replacements.');
}

Future<List<String>> _findDartFiles(Directory dir) async {
  final files = <String>[];

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity.path);
    }
  }

  return files;
}
