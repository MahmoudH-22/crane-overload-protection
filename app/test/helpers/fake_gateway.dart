import 'dart:async';
import 'dart:convert';

import 'package:crane_monitor/core/result.dart';
import 'package:crane_monitor/features/connection/domain/broker_settings.dart';
import 'package:crane_monitor/features/connection/domain/connection_state.dart';
import 'package:crane_monitor/features/connection/domain/mqtt_gateway.dart';

/// In-memory [MqttGateway] for tests: records publishes, injects messages.
class FakeGateway implements MqttGateway {
  /// Creates a gateway, connected at [connectedAt] if [connected].
  FakeGateway({bool connected = true, DateTime? connectedAt}) {
    _current = connected
        ? BrokerConnection(status: BrokerStatus.connected, connectedAt: connectedAt ?? DateTime(2026, 11, 15))
        : const BrokerConnection();
  }

  final _states = StreamController<BrokerConnection>.broadcast(sync: true);
  final _messages = StreamController<InboundMessage>.broadcast(sync: true);
  late BrokerConnection _current;

  /// Every `(topic, payload)` published.
  final published = <(String, String)>[];

  /// `cmd` names published on crane/cmd, in order.
  List<String> get commands => [
    for (final (topic, payload) in published)
      if (topic == 'crane/cmd') (jsonDecode(payload) as Map<String, Object?>)['cmd']! as String,
  ];

  /// Command names excluding PING.
  List<String> get motionCommands => commands.where((c) => c != 'PING').toList();

  /// Simulates the broker link going up or down.
  void setConnected(bool connected, {DateTime? at}) {
    _current = connected
        ? BrokerConnection(status: BrokerStatus.connected, connectedAt: at ?? DateTime(2026, 11, 15))
        : const BrokerConnection(status: BrokerStatus.reconnecting, attempt: 1);
    _states.add(_current);
  }

  /// Delivers [payload] on [topic] as if received from the broker.
  void push(String topic, Object payload) =>
      _messages.add(InboundMessage(topic, payload is String ? payload : jsonEncode(payload)));

  @override
  BrokerConnection get current => _current;

  @override
  Stream<BrokerConnection> get states => _states.stream;

  @override
  Stream<InboundMessage> get messages => _messages.stream;

  @override
  Future<Result<void>> connect(BrokerSettings settings) async {
    setConnected(true);
    return const Ok(null);
  }

  @override
  Future<void> disconnect() async {
    _current = const BrokerConnection();
    _states.add(_current);
  }

  @override
  bool publish(String topic, String payload, {Qos qos = Qos.atLeastOnce}) {
    if (!_current.isConnected) return false;
    published.add((topic, payload));
    return true;
  }

  @override
  void dispose() {
    _states.close();
    _messages.close();
  }
}

/// A `crane/live` JSON map with overridable fields.
Map<String, Object?> liveJson({
  double kg = 0.5,
  double max = 1.5,
  double h = 100,
  double a = 0.1,
  bool top = false,
  String st = 'IDLE',
  String mode = 'REMOTE',
  String src = 'NONE',
}) => {'t': 1000, 'kg': kg, 'max': max, 'h': h, 'a': a, 'top': top, 'st': st, 'mode': mode, 'src': src};
