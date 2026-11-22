// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crane_live.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CraneLive _$CraneLiveFromJson(Map<String, dynamic> json) => _CraneLive(
  millis: (json['t'] as num?)?.toInt() ?? 0,
  kg: (json['kg'] as num).toDouble(),
  maxKg: (json['max'] as num).toDouble(),
  heightMm: (json['h'] as num?)?.toDouble(),
  amps: (json['a'] as num?)?.toDouble(),
  top: json['top'] as bool? ?? false,
  state: $enumDecode(_$CraneStateEnumMap, json['st'], unknownValue: CraneState.unknown),
  mode: $enumDecodeNullable(_$CraneModeEnumMap, json['mode'], unknownValue: CraneMode.unknown) ?? CraneMode.unknown,
  source:
      $enumDecodeNullable(_$MotionSourceEnumMap, json['src'], unknownValue: MotionSource.unknown) ?? MotionSource.none,
  ultrasonicMm: (json['us'] as num?)?.toDouble(),
  obstacle: json['obs'] as bool? ?? false,
);

Map<String, dynamic> _$CraneLiveToJson(_CraneLive instance) => <String, dynamic>{
  't': instance.millis,
  'kg': instance.kg,
  'max': instance.maxKg,
  'h': instance.heightMm,
  'a': instance.amps,
  'top': instance.top,
  'st': _$CraneStateEnumMap[instance.state]!,
  'mode': _$CraneModeEnumMap[instance.mode]!,
  'src': _$MotionSourceEnumMap[instance.source]!,
  'us': instance.ultrasonicMm,
  'obs': instance.obstacle,
};

const _$CraneStateEnumMap = {
  CraneState.idle: 'IDLE',
  CraneState.lifting: 'LIFTING',
  CraneState.lowering: 'LOWERING',
  CraneState.overload: 'OVERLOAD',
  CraneState.jam: 'JAM',
  CraneState.top: 'TOP',
  CraneState.estop: 'ESTOP',
  CraneState.unknown: 'UNKNOWN',
};

const _$CraneModeEnumMap = {CraneMode.local: 'LOCAL', CraneMode.remote: 'REMOTE', CraneMode.unknown: 'UNKNOWN'};

const _$MotionSourceEnumMap = {
  MotionSource.app: 'APP',
  MotionSource.panel: 'PANEL',
  MotionSource.none: 'NONE',
  MotionSource.unknown: 'UNKNOWN',
};
