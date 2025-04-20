import 'package:flutter/cupertino.dart';

class FailureCodes {
  static const invalidEmail = 'invalidEmail';
  static const userDisabled = 'userDisabled';
  static const userNotFound = 'userNotFound';
  static const wrongPassword = 'wrongPassword';
  static const invalidCredential = 'invalidCredential';
  static const wrongCurrentPassword = 'wrongCurrentPassword';
  static const operationNotAllowed = 'operationNotAllowed';
  static const emailAlreadyinUse = 'emailAlreadyinUse';
  static const weakPassword = 'weakPassword';
  static const userMismatch = 'userMismatch';
  static const somethingWentWrong = 'somethingWentWrong';
  static const socialLoginCanceled = 'socialLoginCanceled';
  static const locationServiceDisabled = 'locationServiceDisabled';
  static const locationPermissionDenied = 'locationPermissionDenied';
  static const locationPermissionDeniedForever = 'locationPermissionDeniedForever';
  static const socialProviderError = 'socialProviderError';
  static const tooManyRequests = 'tooManyRequests';
  static const internalError = 'internalError';
  static const noInternet = 'noInternet';
  static const timeout = 'timeout';

  static List<MapEntry<String, String?>> errorList(BuildContext context) {
    return [
      const MapEntry(invalidEmail, 'invalidEmail'),
      const MapEntry(userDisabled, 'userDisabled'),
      const MapEntry(userNotFound, 'userNotFound'),
      const MapEntry(wrongPassword, 'wrongPassword'),
      const MapEntry(invalidCredential, 'invalidCredential'),
      const MapEntry(wrongCurrentPassword, 'invalidCurrentPassword'),
      const MapEntry(operationNotAllowed, 'operationNotAllowed'),
      const MapEntry(emailAlreadyinUse, 'emailAlreadyinUse'),
      const MapEntry(weakPassword, 'weakPassword'),
      const MapEntry(userMismatch, 'userMismatch'),
      const MapEntry(somethingWentWrong, 'somethingWentWrong'),
      const MapEntry(locationServiceDisabled, 'locationServiceDisabled'),
      const MapEntry(locationPermissionDenied, 'locationPermissionDenied'),
      const MapEntry(locationPermissionDeniedForever, 'locationPermissionDenied'),
      const MapEntry(tooManyRequests, 'tooManyRequests'),
      const MapEntry(internalError, 'internalError'),
      const MapEntry(noInternet, 'noInternet'),
      const MapEntry(timeout, 'noInternet'),
      const MapEntry(socialLoginCanceled, null),
      const MapEntry(socialProviderError, null),
    ];
  }
}
