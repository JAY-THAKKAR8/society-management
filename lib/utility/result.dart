import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/failure/custom_failure.dart';

class Result<T> {}

extension ResultExtention<T> on Result<T> {
  FirebaseResult<T> tryCatch({
    required Future<T> Function() run,
    bool ignoreTryCatch = false,
  }) async {
    if (ignoreTryCatch) {
      return right(await run());
    }
    try {
      return right(await run());
    } on FirebaseAuthException catch (e) {
      return left(FirebaseFailure(e));
    } on FirebaseException catch (e) {
      return left(FirebaseFailure(e));
    } catch (e, s) {
      if (e is CustomFailure) {
        return left(e);
      }
      log(e.toString());
      return left(CustomFailure(message: e.toString(), stackTrace: s));
    }
  }
}
