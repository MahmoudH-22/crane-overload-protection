import '../../../core/result.dart';
import 'broker_settings.dart';
import 'connection_state.dart';

/// One message received from the broker.
class InboundMessage {
  /// Creates a message on [topic] with UTF-8 [payload].
  const InboundMessage(this.topic, this.payload);

  /// Topic the message arrived on.
  final String topic;

  /// Decoded UTF-8 payload.
  final String payload;
}

/// MQTT quality-of-service levels used by the app.
enum Qos {
  /// Fire and forget.
  atMostOnce,

  /// Delivered at least once.
  atLeastOnce,
}

/// Abstract MQTT link; the repositories depend on this, not on mqtt_client.
abstract interface class MqttGateway {
  /// Current connection snapshot.
  BrokerConnection get current;

  /// Broadcast stream of connection snapshots.
  Stream<BrokerConnection> get states;

  /// Broadcast stream of received messages.
  Stream<InboundMessage> get messages;

  /// Connects to the broker in [settings] and subscribes to the crane topics.
  ///
  /// Returns [Ok] when connected or [Err] with a readable reason.
  /// After a successful connect, a lost link is retried automatically.
  Future<Result<void>> connect(BrokerSettings settings);

  /// Disconnects on purpose (no auto-reconnect).
  Future<void> disconnect();

  /// Publishes [payload] to [topic] with [qos].
  ///
  /// Returns false when not connected (nothing is sent).
  bool publish(String topic, String payload, {Qos qos = Qos.atLeastOnce});

  /// Releases resources.
  void dispose();
}
