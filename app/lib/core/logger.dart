import 'package:flutter/foundation.dart';

/// Minimal tagged logger (debug builds only).
class Log {
  /// Creates a logger whose lines start with `[tag]`.
  const Log(this.tag);

  /// Prefix printed before each line.
  final String tag;

  /// Prints [message] in debug builds.
  void d(String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  /// Prints [message] and an optional [error] in debug builds.
  void e(String message, [Object? error]) {
    if (kDebugMode) debugPrint('[$tag] ERROR $message${error == null ? '' : ': $error'}');
  }
}
