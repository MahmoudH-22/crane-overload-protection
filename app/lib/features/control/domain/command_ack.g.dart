// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_ack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommandAck _$CommandAckFromJson(Map<String, dynamic> json) =>
    _CommandAck(id: (json['id'] as num).toInt(), ok: json['ok'] as bool, reason: json['reason'] as String?);

Map<String, dynamic> _$CommandAckToJson(_CommandAck instance) => <String, dynamic>{
  'id': instance.id,
  'ok': instance.ok,
  'reason': instance.reason,
};
