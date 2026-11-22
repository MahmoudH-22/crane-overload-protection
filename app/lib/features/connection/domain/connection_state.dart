import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_state.freezed.dart';

/// Phase of the app's link to the MQTT broker.
enum BrokerStatus {
  /// Not connected and not trying.
  disconnected,

  /// First connection attempt in progress.
  connecting,

  /// Connected and subscribed.
  connected,

  /// Connection lost; waiting to retry with back-off.
  reconnecting,

  /// The last user-started attempt failed (see [BrokerConnection.error]).
  failed,
}

/// Snapshot of the broker connection.
@freezed
abstract class BrokerConnection with _$BrokerConnection {
  /// Creates a connection snapshot.
  const factory BrokerConnection({
    @Default(BrokerStatus.disconnected) BrokerStatus status,

    /// User-readable error of the last failure.
    String? error,

    /// When the current connection was established.
    DateTime? connectedAt,

    /// Reconnect attempt number (1-based) while [BrokerStatus.reconnecting].
    @Default(0) int attempt,

    /// Delay before the next reconnect attempt.
    Duration? retryIn,
  }) = _BrokerConnection;

  const BrokerConnection._();

  /// Whether messages can be published right now.
  bool get isConnected => status == BrokerStatus.connected;
}
