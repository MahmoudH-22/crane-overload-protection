import 'package:freezed_annotation/freezed_annotation.dart';

part 'crane_event.freezed.dart';
part 'crane_event.g.dart';

/// Types published on `crane/events`.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum CraneEventType {
  /// Overload latched.
  overload,

  /// Overload cleared.
  overloadCleared,

  /// Jam latched.
  jam,

  /// Reached the top of travel.
  top,

  /// E-stop pressed.
  estop,

  /// E-stop released.
  estopReleased,

  /// Latched fault reset.
  reset,

  /// Scale zeroed.
  tare,

  /// Overload limit changed (kg holds the new limit).
  maxChanged,

  /// Command link lost; app-started motion stopped.
  linkLost,

  /// Ultrasonic sees something under the load; lowering blocked / stopped.
  obstacle,

  /// Space under the load clear again.
  obstacleCleared,

  /// Unrecognised type.
  unknown;

  /// Whether this event is an alarm (shown in red).
  bool get isAlarm => this == overload || this == jam || this == estop || this == linkLost || this == obstacle;

  /// Upper-case wire name, e.g. `OVERLOAD_CLEARED`.
  String get label => name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();
}

/// One `crane/events` message.
@freezed
abstract class CraneEvent with _$CraneEvent {
  /// Creates an event.
  const factory CraneEvent({
    /// Uno `millis()` of the event.
    @JsonKey(name: 't') @Default(0) int millis,

    /// Event type.
    @JsonKey(unknownEnumValue: CraneEventType.unknown) required CraneEventType type,

    /// Weight at the event (new limit for MAX_CHANGED), kg.
    double? kg,

    /// When the app received it (not part of the payload).
    @JsonKey(includeFromJson: false, includeToJson: false) DateTime? receivedAt,
  }) = _CraneEvent;

  /// Decodes a `crane/events` JSON object.
  factory CraneEvent.fromJson(Map<String, Object?> json) => _$CraneEventFromJson(json);
}
