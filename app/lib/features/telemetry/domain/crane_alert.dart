import 'crane_state.dart';
import 'link_health.dart';

/// Condition that shows the red banner and vibrates.
enum CraneAlert {
  /// Overload latched.
  overload('OVERLOAD: load above the limit. Lower the load, then RESET.'),

  /// Motor jam latched.
  jam('JAM: motor stalled. Clear the obstruction, then RESET.'),

  /// Emergency stop pressed.
  estop('E-STOP pressed on the crane. Release it to continue.'),

  /// Ultrasonic sees something under the load (clears by itself).
  obstacle('OBJECT UNDER THE LOAD: lowering blocked until the space below is clear.'),

  /// Crane offline (Last Will or silent > 3 s).
  offline('Crane offline: no data from the crane.');

  /// Creates an alert with its banner [message].
  const CraneAlert(this.message);

  /// Banner text.
  final String message;
}

/// Pure alert rule; the most severe condition wins.
///
/// [health]: link health. [state]: last reported crane state (null if none).
/// [obstacle]: ultrasonic obstacle flag from `crane/live.obs`.
/// Returns the alert to show, or null.
CraneAlert? evaluateAlert({required LinkHealth health, required CraneState? state, bool obstacle = false}) {
  if (health == LinkHealth.offline) return CraneAlert.offline;
  if (health == LinkHealth.disconnected) return null; // shown by the connection badge
  return switch (state) {
    CraneState.estop => CraneAlert.estop,
    CraneState.jam => CraneAlert.jam,
    CraneState.overload => CraneAlert.overload,
    _ when obstacle => CraneAlert.obstacle,
    _ => null,
  };
}
