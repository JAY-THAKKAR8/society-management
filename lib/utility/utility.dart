import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:society_management/app_user/app_user.dart';
import 'package:society_management/constants/app_assets.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:uuid/uuid.dart';

class Utility {
  static Widget progressIndicator({Color? color, double? size}) {
    return Center(
      child: Image.asset(
        AppAssets.loadingGif,
        fit: BoxFit.fill,
        height: size ?? 50,
        width: size ?? 50,
        color: color ?? AppColors.primary,
      ),
    );
  }

  static void toast({required String? message, Color? color}) {
    if (message != null) {
      Fluttertoast.showToast(msg: message, backgroundColor: color ?? AppColors.primary);
    }
  }

  static Future<List<PlatformFile>> pickMultiImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      return result.files;
    } else {
      return [];
    }
  }

  static Widget imageLoader({
    required String url,
    required String placeholder,
    BoxFit? fit,
    BuildContext? context,
    bool isShapeCircular = false,
    BorderRadius? borderRadius,
    Widget? loadingWidget,
    BoxShape? shape,
  }) {
    if (url.trim() == '') {
      return Container(
        decoration: BoxDecoration(
          shape: shape ?? BoxShape.rectangle,
          borderRadius: isShapeCircular ? null : borderRadius ?? BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(placeholder),
            fit: fit ?? BoxFit.cover,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fadeInDuration: const Duration(seconds: 5),
      imageBuilder: (context, imageProvider) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: isShapeCircular ? null : borderRadius ?? BorderRadius.circular(10),
            // borderRadius: borderRadius ?? BorderRadius.circular(10),
            shape: shape ?? BoxShape.rectangle,
            image: DecorationImage(
              image: imageProvider,
              fit: fit ?? BoxFit.cover,
            ),
          ),
        );
      },
      errorWidget: (context, error, dynamic a) => Container(
        decoration: BoxDecoration(
          shape: shape ?? BoxShape.rectangle,
          borderRadius: isShapeCircular ? null : borderRadius ?? BorderRadius.circular(10),
          // borderRadius: borderRadius ??  BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(placeholder),
            fit: fit ?? BoxFit.cover,
          ),
        ),
      ),
      placeholder: (context, url) =>
          loadingWidget ??
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xffebebeb)),
          ),
    );
  }

  static bool isValidEmail(String email) {
    return RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    ).hasMatch(email);
  }

  static Widget noDataWidget({required String text}) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  static Future<DateTime?> datePicker({
    required BuildContext context,
    TextInputType? textInputType,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastdate,
  }) async {
    return await showDatePicker(
      initialEntryMode: DatePickerEntryMode.calendar,
      locale: const Locale('en', 'ZA'),
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ??
          DateTime.now().subtract(
            const Duration(days: 99999),
          ),
      lastDate: lastdate ?? DateTime.now(),
      fieldLabelText: 'dd/MM/yyyy',
      initialDatePickerMode: DatePickerMode.day,
      keyboardType: textInputType,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // dialogBackgroundColor: AppColors.white,
            primaryColor: AppColors.buttonColor,
            focusColor: AppColors.buttonColor,
            colorScheme: const ColorScheme.dark(primary: AppColors.buttonColor),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.buttonColor,
              ),
            ),
          ),
          child: child ?? Container(),
        );
      },
    );
  }

  static String uiDateFormat({DateTime? date}) {
    final today = DateTime.now();
    final String formatter = DateFormat("dd-MM-yyyy").format(date ?? today).split('-').join('-');
    return formatter;
  }

  static setUser(AppUser user) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final users = jsonEncode(user.toJson());
    pref.setString('user', users);
    log(users);
  }

  static Future<AppUser?> getUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final user = pref.getString(
      'user',
    );
    if (user == null) return null;

    final userModel = AppUser.fromJson(jsonDecode(user));
    return userModel;
  }

  static void clearPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.clear();
  }

  static Future<File?> getCompressedFile(
    File file, {
    int? minQuality = 50,
    int? maxQuality = 100,
    double? sizeMbThreshold = 1.0,
  }) async {
    try {
      if (!file.existsSync()) {
        throw Exception('Input file does not exist');
      }

      final extension = path.extension(file.path).toLowerCase();
      final validFormats = ['.jpg', '.jpeg', '.png', '.heic', '.webp'];
      if (!validFormats.contains(extension)) {
        throw Exception('Unsupported image format: $extension');
      }

      final sizeInBytes = file.lengthSync();
      final sizeInMb = sizeInBytes / (1024 * 1024);

      int quality;
      if (sizeInMb >= sizeMbThreshold!) {
        quality = minQuality!;
      } else if (sizeInMb >= sizeMbThreshold / 2) {
        quality = (minQuality! + maxQuality!) ~/ 2;
      } else {
        quality = maxQuality!;
      }

      final tempDir = await getTemporaryDirectory();
      final String uniqueId = const Uuid().v1();
      final outputPath = '${tempDir.path}/$uniqueId$extension';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        outputPath,
        quality: quality,
        rotate: 0,
        keepExif: false,
        autoCorrectionAngle: true,
      );

      if (result == null) {
        throw Exception('Compression failed: null result');
      }

      final compressedFile = File(result.path);
      if (!compressedFile.existsSync() || compressedFile.lengthSync() == 0) {
        throw Exception('Compressed file is invalid or empty');
      }

      return compressedFile;
    } catch (e) {
      log('Image compression error: $e');
      return null;
    }
  }
}
