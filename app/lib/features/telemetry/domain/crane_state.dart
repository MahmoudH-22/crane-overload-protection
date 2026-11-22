import 'package:json_annotation/json_annotation.dart';

/// Crane state reported in `crane/live.st`.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum CraneState {
  /// Stopped, nothing latched.
  idle,

  /// Hook going up.
  lifting,

  /// Hook going down.
  lowering,

  /// Overload latched (lowering still allowed).
  overload,

  /// Motor jam latched.
  jam,

  /// Hook at the top of travel.
  top,

  /// Emergency stop pressed.
  estop,

  /// Value the app does not know (newer firmware).
  unknown;

  /// Upper-case label as shown on the chip.
  String get label => name.toUpperCase();

  /// Whether this state is a latched fault that RESET clears.
  bool get isLatchedFault => this == overload || this == jam;
}

/// Who may command the crane (`crane/live.mode`).
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum CraneMode {
  /// Panel key in LOCAL: the app may only watch (and STOP).
  local,

  /// The app may command.
  remote,

  /// Unrecognised value.
  unknown,
}

/// Who started the current motion (`crane/live.src`).
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum MotionSource {
  /// Started from this app.
  app,

  /// Started from the control panel.
  panel,

  /// No motion.
  none,

  /// Unrecognised value.
  unknown,
}
