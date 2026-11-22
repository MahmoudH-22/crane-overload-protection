import 'package:freezed_annotation/freezed_annotation.dart';

part 'crane_status.freezed.dart';
part 'crane_status.g.dart';

/// Retained `crane/status` message (also the NodeMCU's Last Will).
@freezed
abstract class CraneStatus with _$CraneStatus {
  /// Creates a status; [online] false means the crane dropped off.
  const factory CraneStatus({
    required bool online,
    @JsonKey(name: 'fw') String? firmware,

    /// Sensors / parts the crane has fitted (see [Sensor]); null = not reported (assume all fitted).
    List<String>? sensors,
  }) = _CraneStatus;

  /// Decodes a `crane/status` JSON object.
  factory CraneStatus.fromJson(Map<String, Object?> json) => _$CraneStatusFromJson(json);
}

/// Keys used in `crane/status.sensors`.
abstract final class Sensor {
  /// Load cell (weight).
  static const kg = 'kg';

  /// IR top-of-travel sensor.
  static const top = 'top';

  /// Hook height encoder.
  static const height = 'h';

  /// Motor current sensor.
  static const current = 'a';

  /// Ultrasonic under the basket.
  static const ultrasonic = 'us';

  /// Motor driver (LIFT / LOWER / GOTO possible).
  static const motor = 'motor';
}

/// Whether [key] is fitted according to [fitted] (null = not reported, so assume fitted).
///
/// [fitted]: the reported sensor set. [key]: one of the [Sensor] keys. Returns true if fitted or unknown.
bool isFitted(Set<String>? fitted, String key) => fitted == null || fitted.contains(key);
