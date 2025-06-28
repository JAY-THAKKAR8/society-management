/// Base class for all failures in the application
class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() => 'Failure(message: $message, code: $code, details: $details)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code &&
        other.details == details;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode ^ details.hashCode;
}

/// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.details});
}

/// Server related failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.details});
}

/// Cache related failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.details});
}

/// Authentication related failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.details});
}

/// Validation related failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});
}

/// Permission related failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code, super.details});
}

/// Database related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code, super.details});
}

/// File system related failures
class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message, {super.code, super.details});
}

/// Unknown or unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code, super.details});
}
