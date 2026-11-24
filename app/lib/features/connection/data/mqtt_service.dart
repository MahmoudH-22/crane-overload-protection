import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../../app/constants.dart';
import '../../../core/logger.dart';
import '../../../core/result.dart';
import '../domain/broker_settings.dart';
import '../domain/connection_state.dart';
import '../domain/mqtt_gateway.dart';

const _log = Log('mqtt');

/// [MqttGateway] backed by `mqtt_client` (TCP, Android / desktop).
///
/// Connects, subscribes to the crane topics, decodes payloads and, after a
/// link that was up is lost, reconnects with back-off (1, 2, 4, 8, 15 s…).
/// The crane's Last Will on `crane/status` is handled by the telemetry layer.
class MqttService implements MqttGateway {
  /// Creates an idle service.
  MqttService();

  final _states = StreamController<BrokerConnection>.broadcast();
  final _messages = StreamController<InboundMessage>.broadcast();
  BrokerConnection _current = const BrokerConnection();
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  BrokerSettings? _settings;
  Timer? _retryTimer;
  int _attempt = 0;

  /// Incremented whenever a client is abandoned, so late callbacks are ignored.
  int _generation = 0;

  @override
  BrokerConnection get current => _current;

  @override
  Stream<BrokerConnection> get states => _states.stream;

  @override
  Stream<InboundMessage> get messages => _messages.stream;

  /// Connects to [settings]; see [MqttGateway.connect].
  @override
  Future<Result<void>> connect(BrokerSettings settings) async {
    _retryTimer?.cancel();
    _teardown();
    _settings = settings;
    _attempt = 0;
    _emit(const BrokerConnection(status: BrokerStatus.connecting));
    final result = await _open(settings);
    if (result case Err(:final message)) {
      _emit(BrokerConnection(status: BrokerStatus.failed, error: message));
    }
    return result;
  }

  /// Disconnects on purpose and stops reconnecting.
  @override
  Future<void> disconnect() async {
    _retryTimer?.cancel();
    _settings = null;
    _teardown();
    _emit(const BrokerConnection());
  }

  /// Publishes [payload] on [topic]; returns false when offline.
  @override
  bool publish(String topic, String payload, {Qos qos = Qos.atLeastOnce}) {
    final client = _client;
    if (client == null || !_current.isConnected) return false;
    final builder = MqttClientPayloadBuilder()..addUTF8String(payload);
    try {
      client.publishMessage(topic, _toMqttQos(qos), builder.payload!);
      return true;
    } on Exception catch (e) {
      _log.e('publish $topic failed', e);
      return false;
    }
  }

  /// Closes streams and the client.
  @override
  void dispose() {
    _retryTimer?.cancel();
    _teardown();
    _states.close();
    _messages.close();
  }

  // ------------------------------------------------------------------ internals

  /// Opens one connection to [settings] and subscribes.
  ///
  /// Returns [Ok] on success or [Err] with a readable message.
  Future<Result<void>> _open(BrokerSettings settings) async {
    final gen = ++_generation;
    final client = MqttServerClient.withPort(settings.host, settings.clientId, settings.port)
      ..keepAlivePeriod = 5
      ..disconnectOnNoResponsePeriod = 3
      ..connectTimeoutPeriod = 4000
      ..autoReconnect = false
      ..logging(on: false)
      ..setProtocolV311()
      ..connectionMessage = MqttConnectMessage().withClientIdentifier(settings.clientId).startClean();
    client.onDisconnected = () => _onLost(gen);

    try {
      await client.connect();
    } on Object catch (e) {
      _safeDisconnect(client);
      _log.e('connect ${settings.host}:${settings.port}', e);
      return Err(describeConnectError(e, settings), e);
    }
    if (gen != _generation) {
      _safeDisconnect(client); // superseded by disconnect() / another connect()
      return const Err('Connection cancelled.');
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      final code = client.connectionStatus?.returnCode;
      _safeDisconnect(client);
      return Err('Broker refused the connection (${code?.name ?? 'no reply'}).');
    }

    _client = client;
    for (final topic in Topics.subscribed) {
      client.subscribe(topic, topic == Topics.live ? MqttQos.atMostOnce : MqttQos.atLeastOnce);
    }
    // Socket errors (e.g. Wi-Fi dropped while the phone was locked) arrive on this stream;
    // handle them so they never surface as uncaught exceptions. onDisconnected drives the reconnect.
    _updatesSub = client.updates?.listen(
      _onUpdates,
      onError: (Object e) => _log.e('updates stream error', e),
      cancelOnError: false,
    );
    _attempt = 0;
    _emit(BrokerConnection(status: BrokerStatus.connected, connectedAt: DateTime.now()));
    _log.d('connected to ${settings.host}:${settings.port} as ${settings.clientId}');
    return const Ok(null);
  }

  /// Decodes a batch of received messages onto [messages].
  void _onUpdates(List<MqttReceivedMessage<MqttMessage>> batch) {
    for (final m in batch) {
      final msg = m.payload;
      if (msg is! MqttPublishMessage) continue;
      final text = utf8.decode(msg.payload.message, allowMalformed: true);
      if (!_messages.isClosed) _messages.add(InboundMessage(m.topic, text));
    }
  }

  /// Called by the client when the socket closes; starts reconnecting if the
  /// link was up and the user did not disconnect.
  void _onLost(int gen) {
    if (gen != _generation || !_current.isConnected || _settings == null) return;
    _log.d('connection lost');
    _teardown();
    _scheduleRetry('Connection lost.');
  }

  /// Schedules the next reconnect attempt using the back-off table.
  void _scheduleRetry(String reason) {
    final settings = _settings;
    if (settings == null) return;
    final table = Timing.reconnectBackoff;
    final delay = table[_attempt < table.length ? _attempt : table.length - 1];
    _attempt++;
    _emit(BrokerConnection(status: BrokerStatus.reconnecting, error: reason, attempt: _attempt, retryIn: delay));
    _retryTimer = Timer(delay, () async {
      if (_settings != settings) return;
      final result = await _open(settings);
      if (result case Err(:final message) when _settings == settings) {
        _scheduleRetry(message);
      }
    });
  }

  /// Drops the current client without triggering a reconnect.
  void _teardown() {
    _generation++;
    _updatesSub?.cancel();
    _updatesSub = null;
    final client = _client;
    _client = null;
    if (client != null) _safeDisconnect(client);
  }

  /// Emits [state] as the new current snapshot.
  void _emit(BrokerConnection state) {
    _current = state;
    if (!_states.isClosed) _states.add(state);
  }

  /// Disconnects [client], ignoring errors.
  void _safeDisconnect(MqttServerClient client) {
    try {
      client.disconnect();
    } on Object catch (_) {}
  }

  /// Maps the app's [Qos] to mqtt_client's.
  MqttQos _toMqttQos(Qos qos) => qos == Qos.atMostOnce ? MqttQos.atMostOnce : MqttQos.atLeastOnce;
}

/// Turns a connect exception into a message the user can act on.
///
/// [error]: the thrown object. [settings]: the target broker.
/// Returns a short sentence (refused / timeout / unreachable).
String describeConnectError(Object error, BrokerSettings settings) {
  final where = '${settings.host}:${settings.port}';
  final text = error.toString().toLowerCase();
  final code = error is SocketException ? error.osError?.errorCode : null;
  if (text.contains('refused') || code == 111 || code == 10061) {
    return 'Connection refused by $where. Is Mosquitto running on that port?';
  }
  if (text.contains('timed out') || text.contains('timeout') || code == 110 || code == 10060) {
    return 'Timed out reaching $where. Check the IP and that the phone is on the same hotspot.';
  }
  if (error is SocketException) {
    return 'Cannot reach $where (${error.osError?.message ?? error.message}).';
  }
  if (error is NoConnectionException) {
    return 'No answer from a broker at $where. Check the IP and port.';
  }
  return 'Connection to $where failed: $error';
}
