import 'dart:convert';

/// Command names on `crane/cmd`.
enum CommandType {
  /// Hold-to-run up (repeat every 250 ms).
  lift('LIFT'),

  /// Hold-to-run down (repeat every 250 ms).
  lower('LOWER'),

  /// Hold-to-run move to a target height (value = mm, repeat every 250 ms); the crane stops there itself.
  goTo('GOTO'),

  /// Stop any motion.
  stop('STOP'),

  /// Clear a latched OVERLOAD / JAM.
  reset('RESET'),

  /// Zero the scale.
  tare('TARE'),

  /// Change the overload limit (needs a value).
  setMax('SET_MAX'),

  /// Heartbeat.
  ping('PING');

  /// Creates a type with its [wire] name.
  const CommandType(this.wire);

  /// Name sent in the `cmd` field.
  final String wire;
}

/// One message published on `crane/cmd`.
class CraneCommand {
  /// Creates command [id] of [type], with [value] for SET_MAX.
  const CraneCommand({required this.id, required this.type, this.value});

  /// Message id (0 … 65535, wraps).
  final int id;

  /// Command type.
  final CommandType type;

  /// Optional numeric argument (SET_MAX kg).
  final double? value;

  /// Returns the JSON payload, e.g. `{"id":17,"cmd":"LIFT"}`.
  String toPayload() =>
      jsonEncode({'id': id, 'cmd': type.wire, if (value != null) 'value': double.parse(value!.toStringAsFixed(3))});

  @override
  String toString() => 'CraneCommand($id ${type.wire}${value == null ? '' : ' $value'})';
}

/// Generates command ids that wrap at 65535.
class CommandIdGenerator {
  /// Creates a generator whose first id is [start] + 1.
  CommandIdGenerator([this._last = 0]);

  int _last;

  /// Returns the next id (65535 is followed by 0).
  int next() => _last = (_last + 1) & 0xFFFF;
}
