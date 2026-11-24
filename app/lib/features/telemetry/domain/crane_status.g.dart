// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crane_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CraneStatus _$CraneStatusFromJson(Map<String, dynamic> json) => _CraneStatus(
  online: json['online'] as bool,
  firmware: json['fw'] as String?,
  sensors: (json['sensors'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$CraneStatusToJson(_CraneStatus instance) => <String, dynamic>{
  'online': instance.online,
  'fw': instance.firmware,
  'sensors': instance.sensors,
};
