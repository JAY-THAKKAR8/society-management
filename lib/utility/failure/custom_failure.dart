import 'package:firebase_auth/firebase_auth.dart';

class CustomFailure implements Exception {
  const CustomFailure({
    this.message = 'Unexpected error, please try again',
    this.preFix = 'Exception',
    this.stackTrace,
  });

  final String message;
  final String preFix;
  final StackTrace? stackTrace;

  String get formttedMessgeage {
    var output = '[${preFix.toUpperCase()}] $message';
    if (stackTrace != null) {
      output += '\n\n$stackTrace';
    }
    return output;
  }
}

class JsonParceFailure extends CustomFailure {
  JsonParceFailure(this.error, this.s);

  final Object error;

  final StackTrace s;

  @override
  StackTrace? get stackTrace => s;

  @override
  String get message => '$error';

  @override
  String get preFix => 'Invalid JSON';

  @override
  String toString() => 'JsonParceFailure(error: $error)';
}

class FirebaseFailure extends CustomFailure {
  FirebaseFailure([this.error, this.s]);

  final Object? error;

  final StackTrace? s;

  String get errorMessage {
    if (error == null) return 'Unexpected error, please try again';

    if (error is FirebaseAuthException) {
      final newError = error! as FirebaseAuthException;
      return newError.message.toString();
    }
    if (error is FirebaseException) {
      final newError = error! as FirebaseException;
      return newError.message.toString();
    }
    if (error is FirebaseFailure) {
      final newError = error! as FirebaseFailure;
      return newError.errorMessage;
    }
    return '$error';
  }

  @override
  String get message => errorMessage;

  @override
  StackTrace? get stackTrace => s;

  @override
  String get preFix {
    if (error is FirebaseAuthException) {
      return 'Firebase Auth Error';
    }
    if (error is FirebaseException) {
      return 'Firebase Error';
    }
    if (error is FirebaseFailure) {
      final newError = error! as FirebaseFailure;
      return newError.preFix;
    }

    return 'Error';
  }

  @override
  String toString() => 'FirebaseFailure(error: $error, s: $s)';

  factory FirebaseFailure.unautheticated({String? text}) => FirebaseFailure(text ?? 'Unautheticated');
}

class AuthFailure extends CustomFailure {
  AuthFailure(this.provider, [this.error, this.s]);

  final String provider;
  final Object? error;

  final StackTrace? s;

  @override
  StackTrace? get stackTrace => s;

  @override
  String get message => '$error';

  @override
  String get preFix => '${provider.toUpperCase()} Auth Login Error';

  @override
  String toString() => 'AuthFailure(provider: $provider, error: $error, s: $s)';
}

class SocketFailure extends CustomFailure {
  @override
  String get message => 'No Internet Connections';
}
