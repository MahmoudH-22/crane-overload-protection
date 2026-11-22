import 'dart:async';
import 'dart:convert';

import '../../../app/constants.dart';
import '../../../core/logger.dart';
import '../../connection/domain/mqtt_gateway.dart';
import '../domain/command_ack.dart';
import '../domain/crane_command.dart';

const _log = Log('cmd');

/// Sends commands to the crane and receives acks.
abstract interface class CommandRepository {
  /// Motion currently held (LIFT / LOWER / GOTO), or null.
  CommandType? get activeHold;

  /// Emits whenever [activeHold] changes.
  Stream<CommandType?> get holdChanges;

  /// Refusals and results from `crane/ack`.
  Stream<CommandAck> get acks;

  /// Starts hold-to-run of [type] (LIFT, LOWER, or GOTO with [value] mm):
  /// sends it now and every 250 ms until [releaseHold].
  ///
  /// Calling it again for an active GOTO with a new [value] retargets without stopping.
  void startHold(CommandType type, {double? value});

  /// Stops the repeat timer and sends STOP once (if connected).
  ///
  /// Safe to call when nothing is held; STOP is then only sent if
  /// [stopIfIdle] is true.
  void releaseHold({bool stopIfIdle = false});

  /// Sends a one-shot command ([CommandType.stop], reset, tare, setMax).
  ///
  /// [value]: argument for SET_MAX. Returns false if not connected.
  bool send(CommandType type, {double? value});

  /// Releases timers and subscriptions.
  void dispose();
}

/// [CommandRepository] over an [MqttGateway].
///
/// Also sends PING every second while connected, and stops any hold when the
/// broker connection drops.
class MqttCommandRepository implements CommandRepository {
  /// Creates the repository; starts listening to [gateway].
  MqttCommandRepository(this._gateway, {CommandIdGenerator? ids}) : _ids = ids ?? CommandIdGenerator() {
    _stateSub = _gateway.states.listen((s) => _onConnectionChanged(s.isConnected));
    _onConnectionChanged(_gateway.current.isConnected);
  }

  final MqttGateway _gateway;
  final CommandIdGenerator _ids;
  final _holdChanges = StreamController<CommandType?>.broadcast();
  late final StreamSubscription<Object?> _stateSub;
  Timer? _repeat;
  Timer? _heartbeat;
  CommandType? _activeHold;
  double? _holdValue;

  @override
  CommandType? get activeHold => _activeHold;

  @override
  Stream<CommandType?> get holdChanges => _holdChanges.stream;

  @override
  Stream<CommandAck> get acks => _gateway.messages
      .where((m) => m.topic == Topics.ack)
      .map((m) => parseAck(m.payload))
      .where((a) => a != null)
      .cast<CommandAck>();

  @override
  void startHold(CommandType type, {double? value}) {
    assert(type == CommandType.lift || type == CommandType.lower || type == CommandType.goTo);
    assert(type != CommandType.goTo || value != null, 'GOTO needs a target');
    if (_activeHold == type) {
      if (type == CommandType.goTo && value != _holdValue) {
        _holdValue = value; // retarget; the next repeat (and this one) carry the new value
        if (!_publish(type, value: value)) _stopRepeat();
      }
      return;
    }
    if (_activeHold != null) releaseHold();
    if (!_publish(type, value: value)) return;
    _holdValue = value;
    _setHold(type);
    _repeat = Timer.periodic(Timing.holdRepeat, (_) {
      if (!_publish(type, value: _holdValue)) _stopRepeat();
    });
  }

  @override
  void releaseHold({bool stopIfIdle = false}) {
    final wasHolding = _activeHold != null;
    _stopRepeat();
    if (wasHolding || stopIfIdle) _publish(CommandType.stop);
  }

  @override
  bool send(CommandType type, {double? value}) {
    if (type == CommandType.stop) {
      _stopRepeat();
    }
    return _publish(type, value: value);
  }

  @override
  void dispose() {
    releaseHold();
    _heartbeat?.cancel();
    _stateSub.cancel();
    _holdChanges.close();
  }

  /// Publishes one command; returns false if not connected.
  bool _publish(CommandType type, {double? value}) {
    final cmd = CraneCommand(id: _ids.next(), type: type, value: value);
    final ok = _gateway.publish(Topics.cmd, cmd.toPayload());
    if (type != CommandType.ping && type != _activeHold) _log.d('${ok ? 'sent' : 'NOT sent'} $cmd');
    return ok;
  }

  /// Cancels the repeat timer and clears [activeHold] (no STOP sent).
  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
    _holdValue = null;
    _setHold(null);
  }

  /// Updates [activeHold] and notifies listeners.
  void _setHold(CommandType? value) {
    if (_activeHold == value) return;
    _activeHold = value;
    if (!_holdChanges.isClosed) _holdChanges.add(value);
  }

  /// Starts / stops the heartbeat and drops any hold when the link goes down.
  void _onConnectionChanged(bool connected) {
    if (connected) {
      _heartbeat ??= Timer.periodic(Timing.heartbeat, (_) => _publish(CommandType.ping));
    } else {
      _heartbeat?.cancel();
      _heartbeat = null;
      _stopRepeat(); // cannot send STOP; the crane stops by itself after 600 ms
    }
  }
}

/// Parses a `crane/ack` payload.
///
/// [payload]: UTF-8 JSON. Returns the ack, or null if malformed.
CommandAck? parseAck(String payload) {
  try {
    return CommandAck.fromJson(jsonDecode(payload) as Map<String, Object?>);
  } on Object catch (e) {
    _log.e('bad crane/ack payload: $payload', e);
    return null;
  }
}
