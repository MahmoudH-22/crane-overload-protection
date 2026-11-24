import 'dart:async';

import '../../../core/result.dart';
import '../domain/broker_settings.dart';
import '../domain/connection_state.dart';
import '../domain/mqtt_gateway.dart';

/// [MqttGateway] that routes to the gateway for the chosen [LinkTransport] (Bluetooth or MQTT).
///
/// Only one transport is active at a time; switching disconnects the previous one. States and messages
/// of inactive gateways are ignored.
class TransportGateway implements MqttGateway {
  /// Creates a router over [gateways]; [initial] is active until the first connect.
  TransportGateway(this._gateways, {LinkTransport initial = LinkTransport.bluetooth})
    : assert(_gateways.containsKey(initial), 'no gateway for $initial'),
      _active = initial {
    for (final MapEntry(key: transport, value: gw) in _gateways.entries) {
      _subs
        ..add(gw.states.listen((s) => _forward(transport, () => _states.add(s))))
        ..add(gw.messages.listen((m) => _forward(transport, () => _messages.add(m))));
    }
  }

  final Map<LinkTransport, MqttGateway> _gateways;
  final _states = StreamController<BrokerConnection>.broadcast();
  final _messages = StreamController<InboundMessage>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  LinkTransport _active;

  /// The transport currently in use.
  LinkTransport get active => _active;

  @override
  BrokerConnection get current => _gateways[_active]!.current;

  @override
  Stream<BrokerConnection> get states => _states.stream;

  @override
  Stream<InboundMessage> get messages => _messages.stream;

  /// Switches to [settings].transport if needed (disconnecting the other one) and connects.
  @override
  Future<Result<void>> connect(BrokerSettings settings) async {
    final target = _gateways[settings.transport];
    if (target == null) return Err('${settings.transport.name} is not available in this build.');
    if (settings.transport != _active) {
      await _gateways[_active]!.disconnect();
      _active = settings.transport;
    }
    return target.connect(settings);
  }

  /// Disconnects the active transport.
  @override
  Future<void> disconnect() => _gateways[_active]!.disconnect();

  /// Publishes through the active transport.
  @override
  bool publish(String topic, String payload, {Qos qos = Qos.atLeastOnce}) =>
      _gateways[_active]!.publish(topic, payload, qos: qos);

  /// Disposes every gateway and the streams.
  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    for (final gw in _gateways.values) {
      gw.dispose();
    }
    _states.close();
    _messages.close();
  }

  /// Runs [add] only when [from] is the active transport and the router is open.
  void _forward(LinkTransport from, void Function() add) {
    if (from == _active && !_states.isClosed) add();
  }
}
