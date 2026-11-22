import '../../../app/constants.dart';
import '../../telemetry/domain/crane_live.dart';
import '../../telemetry/domain/crane_state.dart';
import '../../telemetry/domain/crane_status.dart';
import '../../telemetry/domain/link_health.dart';
import 'crane_command.dart';

/// Whether one control is enabled, and why not.
class Availability {
  /// Enabled control.
  const Availability.enabled() : enabled = true, reason = null;

  /// Disabled control with the [reason] shown to the user.
  const Availability.disabled(String this.reason) : enabled = false;

  /// Whether the control can be used.
  final bool enabled;

  /// Why it is disabled (null when enabled).
  final String? reason;

  @override
  bool operator ==(Object other) => other is Availability && other.enabled == enabled && other.reason == reason;

  @override
  int get hashCode => Object.hash(enabled, reason);

  @override
  String toString() => enabled ? 'enabled' : 'disabled($reason)';
}

/// Availability of every control on the panel.
class ControlAvailability {
  /// Creates the set.
  const ControlAvailability({
    required this.lift,
    required this.lower,
    required this.stop,
    required this.reset,
    required this.tare,
    required this.setMax,
    required this.goTo,
  });

  /// All controls disabled with the same [reason].
  ControlAvailability.allDisabled(String reason, {Availability? stop})
    : lift = Availability.disabled(reason),
      lower = Availability.disabled(reason),
      stop = stop ?? Availability.disabled(reason),
      reset = Availability.disabled(reason),
      tare = Availability.disabled(reason),
      setMax = Availability.disabled(reason),
      goTo = Availability.disabled(reason);

  /// LIFT hold button.
  final Availability lift;

  /// LOWER hold button.
  final Availability lower;

  /// STOP button.
  final Availability stop;

  /// RESET button.
  final Availability reset;

  /// TARE button.
  final Availability tare;

  /// Max-load slider.
  final Availability setMax;

  /// GO (hold to move to the target height).
  final Availability goTo;

  @override
  bool operator ==(Object other) =>
      other is ControlAvailability &&
      other.lift == lift &&
      other.lower == lower &&
      other.stop == stop &&
      other.reset == reset &&
      other.tare == tare &&
      other.setMax == setMax &&
      other.goTo == goTo;

  @override
  int get hashCode => Object.hash(lift, lower, stop, reset, tare, setMax, goTo);
}

/// Direction a GOTO from [heightMm] to [targetMm] needs.
///
/// Returns [CommandType.lift], [CommandType.lower], or null when within [CraneLimits.goToToleranceMm].
CommandType? goToDirection({required double heightMm, required double targetMm}) {
  final diff = targetMm - heightMm;
  if (diff.abs() <= CraneLimits.goToToleranceMm) return null;
  return diff > 0 ? CommandType.lift : CommandType.lower;
}

/// Reasons shown on disabled controls.
abstract final class DisabledReason {
  /// Broker not connected.
  static const notConnected = 'Not connected';

  /// No `crane/live` for over 1 s.
  static const stale = 'Data stale';

  /// Crane offline.
  static const offline = 'Crane offline';

  /// Connected but no sample yet.
  static const waiting = 'Waiting for data';

  /// Panel key in LOCAL.
  static const local = 'LOCAL mode (panel has control)';

  /// E-stop pressed.
  static const estop = 'E-stop pressed';

  /// Overload latched.
  static const overload = 'Overload: lower only';

  /// Jam latched.
  static const jam = 'Jam: RESET first';

  /// At the top.
  static const top = 'At top of travel';

  /// RESET with nothing latched.
  static const nothingToReset = 'Nothing to reset';

  /// TARE outside IDLE.
  static const tareIdleOnly = 'Only when IDLE';

  /// Weight above the limit (before the crane latches OVERLOAD).
  static const overMax = 'Load above max';

  /// Ultrasonic sees something under the load.
  static const obstacle = 'Object under the load';

  /// Motor driver not wired yet (crane reports no "motor").
  static const noMotor = 'Motor not connected';

  /// GO without the height encoder.
  static const noHeight = 'No height sensor';

  /// GO with no target chosen.
  static const pickTarget = 'Pick a height';

  /// GO with the hook already at the target.
  static const atTarget = 'At target';
}

/// Pure rule: which controls are enabled, and why not.
///
/// [connected]: the app is connected to the broker.
/// [health]: freshness of the crane data.
/// [live]: last `crane/live` sample (null if none yet).
/// [targetMm]: chosen go-to height (null if none).
/// [fitted]: sensors the crane reports (`crane/status.sensors`); null = not reported, assume all.
/// Returns the [ControlAvailability] for the panel.
///
/// STOP stays enabled whenever the broker is connected; the crane, not the
/// app, decides everything else, so these rules only avoid pointless requests.
/// GO follows the LIFT rule when the target is above the hook and the LOWER
/// rule when it is below.
ControlAvailability evaluateControls({
  required bool connected,
  required LinkHealth health,
  required CraneLive? live,
  double? targetMm,
  Set<String>? fitted,
}) {
  if (!connected || health == LinkHealth.disconnected) {
    return ControlAvailability.allDisabled(DisabledReason.notConnected);
  }
  const stop = Availability.enabled();
  if (health == LinkHealth.offline) {
    return ControlAvailability.allDisabled(DisabledReason.offline, stop: stop);
  }
  if (health == LinkHealth.stale) {
    return ControlAvailability.allDisabled(DisabledReason.stale, stop: stop);
  }
  if (live == null) {
    return ControlAvailability.allDisabled(DisabledReason.waiting, stop: stop);
  }
  if (live.mode == CraneMode.local) {
    return ControlAvailability.allDisabled(DisabledReason.local, stop: stop);
  }
  if (live.state == CraneState.estop) {
    return ControlAvailability.allDisabled(DisabledReason.estop, stop: stop);
  }

  final state = live.state;
  final atTop = state == CraneState.top || live.top;
  final lift = switch (state) {
    CraneState.overload => const Availability.disabled(DisabledReason.overload),
    CraneState.jam => const Availability.disabled(DisabledReason.jam),
    _ when atTop => const Availability.disabled(DisabledReason.top),
    _ when live.kg > live.maxKg => const Availability.disabled(DisabledReason.overMax),
    _ => const Availability.enabled(),
  };
  final lower = state == CraneState.jam
      ? const Availability.disabled(DisabledReason.jam)
      : live.obstacle
      ? const Availability.disabled(DisabledReason.obstacle)
      : const Availability.enabled();
  final reset = state.isLatchedFault
      ? const Availability.enabled()
      : const Availability.disabled(DisabledReason.nothingToReset);
  final tare = state == CraneState.idle
      ? const Availability.enabled()
      : const Availability.disabled(DisabledReason.tareIdleOnly);

  final height = live.heightMm;
  final direction = targetMm == null || height == null ? null : goToDirection(heightMm: height, targetMm: targetMm);
  final goTo = height == null || !isFitted(fitted, Sensor.height)
      ? const Availability.disabled(DisabledReason.noHeight)
      : targetMm == null
      ? const Availability.disabled(DisabledReason.pickTarget)
      : switch (direction) {
          null => const Availability.disabled(DisabledReason.atTarget),
          CommandType.lift => lift,
          _ => lower,
        };

  // Without a motor nothing can move: say so instead of letting the crane refuse every press.
  const noMotor = Availability.disabled(DisabledReason.noMotor);
  final motor = isFitted(fitted, Sensor.motor);

  return ControlAvailability(
    lift: motor ? lift : noMotor,
    lower: motor ? lower : noMotor,
    stop: stop,
    reset: reset,
    tare: tare,
    setMax: const Availability.enabled(),
    goTo: motor ? goTo : noMotor,
  );
}
