import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// A received MQTT message as text.
typedef MqttText = ({String topic, String payload});

/// Thin wrapper around mqtt_client: connect, subscribe, publish, and one message stream.
class MqttDataSource {
  MqttServerClient? _client;
  StreamSubscription<Object?>? _sub;
  final _messages = StreamController<MqttText>.broadcast();

  /// All messages on the subscribed topics.
  Stream<MqttText> get messages => _messages.stream;

  /// True while the client is connected.
  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// Connects to [host]:[port] and subscribes to [topics].
  ///
  /// Auto-reconnect and re-subscribe are enabled. Throws [StateError] when
  /// the broker refuses or cannot be reached.
  Future<void> connect(String host, int port, List<String> topics) async {
    await disconnect();
    final client = MqttServerClient.withPort(
        host, 'crane-app-${DateTime.now().millisecondsSinceEpoch}', port)
      ..keepAlivePeriod = 15
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..logging(on: false);
    client.connectionMessage = MqttConnectMessage().startClean();
    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
      throw StateError('Cannot reach broker $host:$port ($e)');
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      client.disconnect();
      throw StateError('Broker refused the connection: ${client.connectionStatus}');
    }
    for (final t in topics) {
      client.subscribe(t, MqttQos.atLeastOnce);
    }
    _sub = client.updates?.listen((events) {
      for (final e in events) {
        final msg = e.payload as MqttPublishMessage;
        _messages.add((
          topic: e.topic,
          payload: MqttPublishPayload.bytesToStringAsString(msg.payload.message),
        ));
      }
    });
    _client = client;
  }

  /// Publishes [payload] on [topic] with QoS 1. Throws [StateError] when offline.
  void publish(String topic, String payload) {
    final c = _client;
    if (c == null || !isConnected) throw StateError('Not connected to the broker');
    final builder = MqttClientPayloadBuilder()..addString(payload);
    c.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Unsubscribes and disconnects. Safe to call when already disconnected.
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    _client?.disconnect();
    _client = null;
  }
}
