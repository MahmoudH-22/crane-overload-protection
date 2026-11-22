/// A success-or-failure value, used instead of throwing across layers.
sealed class Result<T> {
  /// Base constructor.
  const Result();

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;
}

/// A successful [Result] holding [value].
final class Ok<T> extends Result<T> {
  /// Creates a success with [value].
  const Ok(this.value);

  /// The success value.
  final T value;
}

/// A failed [Result] holding a user-readable [message].
final class Err<T> extends Result<T> {
  /// Creates a failure with [message] and an optional [cause].
  const Err(this.message, [this.cause]);

  /// Message suitable for showing to the user.
  final String message;

  /// Underlying error, for logging.
  final Object? cause;
}
