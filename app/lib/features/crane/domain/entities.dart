/// Domain entities for the crane. Pure Dart: no Flutter, no MQTT.
library;

/// States reported by the Uno safety controller.
enum CraneState { idle, lifting, lowering, atTop, overload, jam, eStop, unknown }

/// Maps the firmware's wire name (e.g. "AT_TOP") to a [CraneState].
///
/// [wire] is the state string from crane/live. Returns [CraneState.unknown]
/// for anything unexpected.
CraneState craneStateFromWire(String wire) => switch (wire) {
      'IDLE' => CraneState.idle,
      'LIFTING' => CraneState.lifting,
      'LOWERING' => CraneState.lowering,
      'AT_TOP' => CraneState.atTop,
      'OVERLOAD' => CraneState.overload,
      'JAM' => CraneState.jam,
      'E_STOP' => CraneState.eStop,
      _ => CraneState.unknown,
    };

/// One telemetry snapshot published on crane/live.
class CraneTelemetry {
  /// Creates a snapshot; [receivedAt] is the phone time it arrived.
  const CraneTelemetry({
    required this.kg,
    required this.amps,
    required this.atTop,
    required this.state,
    required this.maxKg,
    required this.nearLimit,
    required this.linkLost,
    required this.homed,
    required this.heightMm,
    required this.encoderErrors,
    required this.receivedAt,
  });

  final double kg;
  final double amps;
  final bool atTop;
  final CraneState state;
  final double maxKg;
  final bool nearLimit;
  final bool linkLost;

  /// True after the hook has touched the top switch once (encoder zero set).
  final bool homed;

  /// Hook height above its lowest point in mm, from the encoder; null until homed.
  final double? heightMm;

  /// True if the encoder decoder has seen invalid (noisy or missed) transitions.
  final bool encoderErrors;
  final DateTime receivedAt;

  /// True for latched faults that need RESET: overload, jam, E-stop.
  bool get isFault =>
      state == CraneState.overload || state == CraneState.jam || state == CraneState.eStop;

  /// Load as a fraction of the overload limit (can be above 1).
  double get loadRatio => maxKg <= 0 ? 0 : kg / maxKg;

  /// True when lifting is not allowed, so the app can disable the button.
  bool get liftBlocked => isFault || atTop;
}

/// Command types accepted on crane/cmd.
enum CraneCommandType { up, down, stop, reset, max, tare, cal }

/// A command with an optional numeric [value] (used by MAX and CAL).
class CraneCommand {
  /// Creates a command of [type] with an optional [value].
  const CraneCommand(this.type, [this.value]);

  final CraneCommandType type;
  final double? value;
}

/// MQTT broker connection settings.
class BrokerSettings {
  /// Creates settings for [host]:[port].
  const BrokerSettings({required this.host, required this.port});

  /// Default for a laptop broker on an Android phone hotspot.
  static const fallback = BrokerSettings(host: '192.168.43.10', port: 1883);

  final String host;
  final int port;

  /// Returns a copy with the given fields replaced.
  BrokerSettings copyWith({String? host, int? port}) =>
      BrokerSettings(host: host ?? this.host, port: port ?? this.port);
}
