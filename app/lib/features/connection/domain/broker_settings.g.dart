// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broker_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BrokerSettings _$BrokerSettingsFromJson(Map<String, dynamic> json) => _BrokerSettings(
  transport: $enumDecodeNullable(_$LinkTransportEnumMap, json['transport']) ?? LinkTransport.bluetooth,
  btAddress: json['btAddress'] as String? ?? '',
  btName: json['btName'] as String? ?? '',
  host: json['host'] as String,
  port: (json['port'] as num?)?.toInt() ?? BrokerDefaults.port,
  clientId: json['clientId'] as String,
);

Map<String, dynamic> _$BrokerSettingsToJson(_BrokerSettings instance) => <String, dynamic>{
  'transport': _$LinkTransportEnumMap[instance.transport]!,
  'btAddress': instance.btAddress,
  'btName': instance.btName,
  'host': instance.host,
  'port': instance.port,
  'clientId': instance.clientId,
};

const _$LinkTransportEnumMap = {LinkTransport.bluetooth: 'bluetooth', LinkTransport.mqtt: 'mqtt'};
