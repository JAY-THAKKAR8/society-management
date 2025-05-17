/// A class representing a failure in the application.
class Failure {
  /// The error message.
  final String message;

  /// Creates a new [Failure] with the given [message].
  const Failure(this.message);

  @override
  String toString() => 'Failure: $message';
}
