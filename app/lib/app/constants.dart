/// App-wide constants: MQTT topics, crane limits and timing rules.
///
/// These values mirror the MQTT contract in `CLAUDE.md`; the Uno firmware and
/// `tools/crane_sim.py` use the same numbers.
library;

/// MQTT topic names.
abstract final class Topics {
  /// Live telemetry, crane → app, ~5 Hz, QoS 0.
  static const live = 'crane/live';

  /// Commands, app → crane, QoS 1.
  static const cmd = 'crane/cmd';

  /// Command results / refusals, crane → app, QoS 1.
  static const ack = 'crane/ack';

  /// Safety and state events, crane → app, QoS 1.
  static const events = 'crane/events';

  /// Online flag (retained, Last Will), crane → app, QoS 1.
  static const status = 'crane/status';

  /// Every topic the app subscribes to.
  static const subscribed = [live, ack, events, status];
}

/// Physical limits of the crane.
abstract final class CraneLimits {
  /// Highest selectable overload limit, kg (the Uno clamps to this).
  static const maxLimitKg = 1.5;

  /// Lowest selectable overload limit, kg.
  static const minLimitKg = 0.5;

  /// Full scale of the weight gauge and chart, kg.
  static const gaugeFullScaleKg = 2.0;

  /// Fraction of max at which the gauge turns amber.
  static const nearFraction = 0.9;

  /// Hook height at the top of travel, mm.
  static const topMm = 346.0;

  /// Start of the top-stop zone drawn on the height bar, mm.
  static const topZoneStartMm = 326.0;

  /// Soft bottom limit (lowest GOTO target), mm.
  static const bottomMm = 5.0;

  /// GOTO counts as arrived within this distance, mm (same on the crane).
  static const goToToleranceMm = 3.0;
}

/// Timing rules shared with the crane.
abstract final class Timing {
  /// Repeat period for LIFT / LOWER while a hold button is down.
  static const holdRepeat = Duration(milliseconds: 250);

  /// Heartbeat (PING) period while connected.
  static const heartbeat = Duration(seconds: 1);

  /// Live data older than this is "stale".
  static const staleAfter = Duration(seconds: 1);

  /// Live data older than this means "crane offline".
  static const offlineAfter = Duration(seconds: 3);

  /// Window of the live weight chart.
  static const chartWindow = Duration(seconds: 30);

  /// Window of the motor-current sparkline.
  static const sparklineWindow = Duration(seconds: 10);

  /// UI refresh tick used for staleness checks.
  static const uiTick = Duration(milliseconds: 250);

  /// Reconnect back-off sequence; the last value repeats.
  static const reconnectBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];
}

/// Default broker settings.
abstract final class BrokerDefaults {
  /// Default Mosquitto port.
  static const port = 1883;

  /// Default host (the laptop on the phone hotspot is usually 192.168.x.x).
  static const host = '192.168.43.10';
}

/// Number of events kept in memory.
const kMaxEvents = 200;
