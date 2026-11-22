// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crane_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CraneEvent _$CraneEventFromJson(Map<String, dynamic> json) => _CraneEvent(
  millis: (json['t'] as num?)?.toInt() ?? 0,
  type: $enumDecode(_$CraneEventTypeEnumMap, json['type'], unknownValue: CraneEventType.unknown),
  kg: (json['kg'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CraneEventToJson(_CraneEvent instance) => <String, dynamic>{
  't': instance.millis,
  'type': _$CraneEventTypeEnumMap[instance.type]!,
  'kg': instance.kg,
};

const _$CraneEventTypeEnumMap = {
  CraneEventType.overload: 'OVERLOAD',
  CraneEventType.overloadCleared: 'OVERLOAD_CLEARED',
  CraneEventType.jam: 'JAM',
  CraneEventType.top: 'TOP',
  CraneEventType.estop: 'ESTOP',
  CraneEventType.estopReleased: 'ESTOP_RELEASED',
  CraneEventType.reset: 'RESET',
  CraneEventType.tare: 'TARE',
  CraneEventType.maxChanged: 'MAX_CHANGED',
  CraneEventType.linkLost: 'LINK_LOST',
  CraneEventType.obstacle: 'OBSTACLE',
  CraneEventType.obstacleCleared: 'OBSTACLE_CLEARED',
  CraneEventType.unknown: 'UNKNOWN',
};
