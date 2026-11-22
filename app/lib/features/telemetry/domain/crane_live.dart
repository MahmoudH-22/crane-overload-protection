import 'package:freezed_annotation/freezed_annotation.dart';

import 'crane_state.dart';

part 'crane_live.freezed.dart';
part 'crane_live.g.dart';

/// One `crane/live` telemetry sample.
@freezed
abstract class CraneLive with _$CraneLive {
  /// Creates a sample; JSON keys follow the MQTT contract.
  const factory CraneLive({
    /// Uno `millis()` when the sample was taken.
    @JsonKey(name: 't') @Default(0) int millis,

    /// Weight on the hook (tared), kg.
    @JsonKey(name: 'kg') required double kg,

    /// Current overload limit, kg.
    @JsonKey(name: 'max') required double maxKg,

    /// Hook height, mm (0 = table); null when the encoder is not fitted.
    @JsonKey(name: 'h') double? heightMm,

    /// Motor current, A; null when the current sensor is not fitted.
    @JsonKey(name: 'a') double? amps,

    /// IR top-of-travel sensor active.
    @Default(false) bool top,

    /// Crane state.
    @JsonKey(name: 'st', unknownEnumValue: CraneState.unknown) required CraneState state,

    /// LOCAL / REMOTE.
    @JsonKey(unknownEnumValue: CraneMode.unknown) @Default(CraneMode.unknown) CraneMode mode,

    /// Who started the current motion.
    @JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown) @Default(MotionSource.none) MotionSource source,

    /// Ultrasonic distance below the basket, mm (null = no echo / too close).
    @JsonKey(name: 'us') double? ultrasonicMm,

    /// Something is under the load (debounced on the Uno); lowering is blocked.
    @JsonKey(name: 'obs') @Default(false) bool obstacle,
  }) = _CraneLive;

  /// Decodes a `crane/live` JSON object.
  factory CraneLive.fromJson(Map<String, Object?> json) => _$CraneLiveFromJson(json);
}
