import 'dart:async';
import 'dart:convert';

import '../../../app/constants.dart';
import '../../../core/logger.dart';
import '../../../core/result.dart';
import '../domain/bluetooth_port.dart';
import '../domain/broker_settings.dart';
import '../domain/connection_state.dart';
import '../domain/mqtt_gateway.dart';
import 'crane_link_codec.dart';

const _log = Log('bt');

/// [MqttGateway] over the HC-05 Bluetooth serial link to the Uno.
///
/// Speaks the Uno's `crane_link.h` lines and presents them as the same topic + JSON messages the MQTT
/// contract defines, so the telemetry, control and events repositories do not know which link is used.
/// Also produces `crane/status` the way the NodeMCU did: online while the Uno talks, offline after
/// [unoSilentAfter] without a valid line, `sensors` from the `S` line.
/// A link that was up and drops is reopened with the same back-off as MQTT (1, 2, 4, 8, 15 s…).
class BluetoothGateway implements MqttGateway, PairedDeviceSource {
  /// Creates an idle gateway on [port]; [clock] is injectable for tests.
  BluetoothGateway(this._port, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Firmware tag reported in `crane/status.fw` for a Bluetooth crane.
  static const fwTag = 'uno-bt';

  /// No valid line from the Uno for this long → `crane/status.online = false` (same as the NodeMCU).
  static const unoSilentAfter = Duration(seconds: 2);

  /// Give up opening the link after this long.
  static const openTimeout = Duration(seconds: 12);

  final BluetoothPort _port;
  final DateTime Function() _clock;
  final _states = StreamController<BrokerConnection>.broadcast();
  final _messages = StreamController<InboundMessage>.broadcast();
  final _splitter = ByteLineSplitter();
  BrokerConnection _current = const BrokerConnection();
  BluetoothLink? _link;
  StreamSubscription<List<int>>? _inputSub;
  BrokerSettings? _settings;
  Timer? _retryTimer;
  Timer? _silenceTimer;
  int _attempt = 0;

  /// Incremented whenever a link is abandoned, so late callbacks are ignored.
  int _generation = 0;

  /// When the last valid line arrived.
  DateTime? _lastLine;

  /// Online flag last published on crane/status (null = nothing published on this link yet).
  bool? _online;

  /// Fitted sensors from the last `S` line (null = not reported yet).
  List<String>? _sensors;

  @override
  BrokerConnection get current => _current;

  @override
  Stream<BrokerConnection> get states => _states.stream;

  @override
  Stream<InboundMessage> get messages => _messages.stream;

  /// Lists the phone's paired devices (pick the HC-05).
  @override
  Future<Result<List<PairedDevice>>> pairedDevices() => _port.pairedDevices();

  /// Opens the Bluetooth link to [settings].btAddress; see [MqttGateway.connect].
  @override
  Future<Result<void>> connect(BrokerSettings settings) async {
    _retryTimer?.cancel();
    _teardown();
    _settings = settings;
    _attempt = 0;
    _emit(const BrokerConnection(status: BrokerStatus.connecting));
    final result = await _open(settings);
    if (result case Err(:final message) when _settings == settings) {
      _emit(BrokerConnection(status: BrokerStatus.failed, error: message));
    }
    return result;
  }

  /// Closes the link on purpose and stops reconnecting.
  @override
  Future<void> disconnect() async {
    _retryTimer?.cancel();
    _settings = null;
    _teardown();
    _emit(const BrokerConnection());
  }

  /// Sends a crane/cmd [payload] as a `C` line; other topics are ignored.
  ///
  /// [qos] does not apply to a serial link. Returns false when not connected or the command is invalid.
  @override
  bool publish(String topic, String payload, {Qos qos = Qos.atLeastOnce}) {
    final link = _link;
    if (topic != Topics.cmd || link == null || !_current.isConnected) return false;
    final line = CraneLinkCodec.commandLine(payload);
    if (line == null) {
      _log.e('not sent (invalid command): $payload');
      return false;
    }
    try {
      link.write(ascii.encode(line));
      return true;
    } on Object catch (e) {
      _log.e('write failed', e);
      return false;
    }
  }

  /// Closes streams and the link.
  @override
  void dispose() {
    _retryTimer?.cancel();
    _teardown();
    _states.close();
    _messages.close();
  }

  // ------------------------------------------------------------------ internals

  /// Opens one link to [settings] and starts reading.
  ///
  /// Returns [Ok] on success or [Err] with a readable message.
  Future<Result<void>> _open(BrokerSettings settings) async {
    final gen = ++_generation;
    if (settings.btAddress.isEmpty) return const Err('Pick the crane (HC-05) from the paired devices first.');
    final Result<BluetoothLink> opened;
    try {
      opened = await _port.open(settings.btAddress).timeout(openTimeout);
    } on TimeoutException {
      return Err('No answer from ${settings.targetLabel}. Is the crane powered and the HC-05 LED blinking?');
    }
    switch (opened) {
      case Err(:final message, :final cause):
        return Err(message, cause);
      case Ok(value: final link):
        if (gen != _generation) {
          unawaited(link.close()); // superseded by disconnect() / another connect()
          return const Err('Connection cancelled.');
        }
        _link = link;
        _splitter.reset();
        _lastLine = null;
        _online = null;
        _sensors = null;
        _inputSub = link.input.listen(
          _onBytes,
          onError: (Object e) => _log.e('input error', e),
          onDone: () => _onLost(gen),
          cancelOnError: false,
        );
        _silenceTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _checkSilence());
        _attempt = 0;
        _emit(BrokerConnection(status: BrokerStatus.connected, connectedAt: _clock()));
        _log.d('connected to ${settings.targetLabel}');
        return const Ok(null);
    }
  }

  /// Splits received [bytes] into lines and publishes what they carry.
  void _onBytes(List<int> bytes) {
    for (final line in _splitter.add(bytes)) {
      final body = CraneLinkCodec.unframe(line);
      if (body == null) continue; // noise or a bad checksum: drop, like the NodeMCU
      _lastLine = _clock();
      var statusChanged = _online != true;
      final sensors = CraneLinkCodec.sensors(body.split(','));
      if (sensors != null && !_sameList(sensors, _sensors)) {
        _sensors = sensors;
        statusChanged = true;
      }
      if (statusChanged) _publishStatus(online: true);
      final msg = CraneLinkCodec.toMessage(body);
      if (msg != null) _add(msg);
    }
  }

  /// Publishes crane/status offline when the Uno has been silent for [unoSilentAfter].
  void _checkSilence() {
    final last = _lastLine;
    if (_online == true && last != null && _clock().difference(last) > unoSilentAfter) {
      _publishStatus(online: false);
    }
  }

  /// Emits a crane/status message with [online] and the known sensors.
  void _publishStatus({required bool online}) {
    _online = online;
    _add(InboundMessage(Topics.status, CraneLinkCodec.statusJson(online: online, fw: fwTag, sensors: _sensors)));
  }

  /// Called when the link closes; starts reconnecting if it was up and the user did not disconnect.
  void _onLost(int gen) {
    if (gen != _generation || !_current.isConnected || _settings == null) return;
    _log.d('link lost');
    _teardown();
    _scheduleRetry('Bluetooth link lost.');
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

  /// Drops the current link without triggering a reconnect.
  void _teardown() {
    _generation++;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _inputSub?.cancel();
    _inputSub = null;
    final link = _link;
    _link = null;
    if (link != null) {
      link.close().catchError((Object e) => _log.e('close failed', e));
    }
  }

  /// Emits [state] as the new current snapshot.
  void _emit(BrokerConnection state) {
    _current = state;
    if (!_states.isClosed) _states.add(state);
  }

  /// Adds [msg] to [messages] unless disposed.
  void _add(InboundMessage msg) {
    if (!_messages.isClosed) _messages.add(msg);
  }

  /// Whether [a] and [b] hold the same names in the same order.
  static bool _sameList(List<String> a, List<String>? b) =>
      b != null && a.length == b.length && Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
}
