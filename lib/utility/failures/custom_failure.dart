// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:society_management/utility/failures/failure_codes.dart';

class CustomFailure implements Exception {
  const CustomFailure({
    this.message = 'Something went wrong. Please try again.',
    this.preFix = 'Exception',
    this.stackTrace,
    this.providerIds,
    this.failedEmail,
    this.code = FailureCodes.somethingWentWrong,
  });

  factory CustomFailure.fromFirebaseAuth(FirebaseAuthException e) {
    return CustomFailure(
      code: e.code,
      message: e.message ?? 'Something went wrong. Please try again.',
      preFix: 'FirebaseAuth',
    );
  }
  factory CustomFailure.fromFirebase(FirebaseException e) {
    return CustomFailure(
      code: e.code,
      message: e.message ?? 'Something went wrong. Please try again.',
      preFix: e.plugin,
    );
  }
  factory CustomFailure.socialLoginCanceled() {
    return const CustomFailure(code: FailureCodes.socialLoginCanceled);
  }

  factory CustomFailure.userNotFound() {
    return const CustomFailure(code: FailureCodes.userNotFound);
  }

  factory CustomFailure.wrongPassword() {
    return const CustomFailure(code: FailureCodes.wrongCurrentPassword);
  }

  factory CustomFailure.locationServiceDisabled() {
    return const CustomFailure(code: FailureCodes.locationServiceDisabled);
  }

  factory CustomFailure.locationPermissionDenied() {
    return const CustomFailure(code: FailureCodes.locationPermissionDenied);
  }

  factory CustomFailure.locationPermissionDeniedForever() {
    return const CustomFailure(code: FailureCodes.locationPermissionDeniedForever);
  }

  factory CustomFailure.forgotPasswordSocialProvider(String? providerIds) {
    return CustomFailure(code: FailureCodes.socialProviderError, providerIds: providerIds);
  }
  factory CustomFailure.noInternet() {
    return const CustomFailure(code: FailureCodes.noInternet);
  }

  factory CustomFailure.timeout() => const CustomFailure(code: FailureCodes.noInternet);

  final String message;
  final String preFix;
  final StackTrace? stackTrace;
  final String? code;
  final String? providerIds;
  final String? failedEmail;

  String get formttedMessgeage {
    var output = '[${preFix.toUpperCase()}] $message';
    if (stackTrace != null) {
      output += '\n\n$stackTrace';
    }

    if (code != null) {
      output += '\n\nCode: $code';
    }
    return output;
  }

  String? getAppErrorMessage(BuildContext context, {bool shouldReturnNull = false}) {
    var getFormmtedCode = (code ?? '').toCamelCase().toLowerCase();
    if (getFormmtedCode.startsWith('auth/')) {
      getFormmtedCode = getFormmtedCode.replaceAll('auth/', '');
    }
    final seachedErrorKey =
        FailureCodes.errorList(context).firstWhereOrNull((e) => e.key.toLowerCase() == getFormmtedCode);

    if (shouldReturnNull && seachedErrorKey == null) {
      return null;
    }
    if (seachedErrorKey == null) {
      return 'somethingWentWrong';
    }
    if (seachedErrorKey.value == FailureCodes.socialProviderError) {
      return '${'thisAccountUse'} ${providerIds ?? 'different'} ${'authenticationPleaseUseTheAppropriateSocialLoginMethod'}';
    }
    return seachedErrorKey.value;
  }

  CustomFailure copyWith({
    String? message,
    String? preFix,
    StackTrace? stackTrace,
    String? code,
    String? providerIds,
    String? failedEmail,
  }) {
    return CustomFailure(
      message: message ?? this.message,
      preFix: preFix ?? this.preFix,
      stackTrace: stackTrace ?? this.stackTrace,
      code: code ?? this.code,
      providerIds: providerIds ?? this.providerIds,
      failedEmail: failedEmail ?? this.failedEmail,
    );
  }
}
