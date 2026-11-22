// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'broker_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BrokerSettings {

 LinkTransport get transport;/// MAC address of the paired HC-05, e.g. `98:D3:31:F5:12:34`.
 String get btAddress;/// Name of the paired HC-05 (shown in the UI).
 String get btName; String get host; int get port; String get clientId;
/// Create a copy of BrokerSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrokerSettingsCopyWith<BrokerSettings> get copyWith => _$BrokerSettingsCopyWithImpl<BrokerSettings>(this as BrokerSettings, _$identity);

  /// Serializes this BrokerSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BrokerSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrokerSettings&&(identical(other.transport, _this.transport) || other.transport == _this.transport)&&(identical(other.btAddress, _this.btAddress) || other.btAddress == _this.btAddress)&&(identical(other.btName, _this.btName) || other.btName == _this.btName)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.port, _this.port) || other.port == _this.port)&&(identical(other.clientId, _this.clientId) || other.clientId == _this.clientId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BrokerSettings;
  return Object.hash(runtimeType,_this.transport,_this.btAddress,_this.btName,_this.host,_this.port,_this.clientId);
}

@override
String toString() {
  final _this = this as BrokerSettings;
  return 'BrokerSettings(transport: ${_this.transport}, btAddress: ${_this.btAddress}, btName: ${_this.btName}, host: ${_this.host}, port: ${_this.port}, clientId: ${_this.clientId})';
}


}

/// @nodoc
abstract mixin class $BrokerSettingsCopyWith<$Res>  {
  factory $BrokerSettingsCopyWith(BrokerSettings value, $Res Function(BrokerSettings) _then) = _$BrokerSettingsCopyWithImpl;
@useResult
$Res call({
 LinkTransport transport, String btAddress, String btName, String host, int port, String clientId
});




}
/// @nodoc
class _$BrokerSettingsCopyWithImpl<$Res>
    implements $BrokerSettingsCopyWith<$Res> {
  _$BrokerSettingsCopyWithImpl(this._self, this._then);

  final BrokerSettings _self;
  final $Res Function(BrokerSettings) _then;

/// Create a copy of BrokerSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transport = null,Object? btAddress = null,Object? btName = null,Object? host = null,Object? port = null,Object? clientId = null,}) {
  return _then(BrokerSettings(
transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as LinkTransport,btAddress: null == btAddress ? _self.btAddress : btAddress // ignore: cast_nullable_to_non_nullable
as String,btName: null == btName ? _self.btName : btName // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BrokerSettings].
extension BrokerSettingsPatterns on BrokerSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrokerSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrokerSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrokerSettings value)  $default,){
final _that = this;
switch (_that) {
case _BrokerSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrokerSettings value)?  $default,){
final _that = this;
switch (_that) {
case _BrokerSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LinkTransport transport,  String btAddress,  String btName,  String host,  int port,  String clientId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrokerSettings() when $default != null:
return $default(_that.transport,_that.btAddress,_that.btName,_that.host,_that.port,_that.clientId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LinkTransport transport,  String btAddress,  String btName,  String host,  int port,  String clientId)  $default,) {final _that = this;
switch (_that) {
case _BrokerSettings():
return $default(_that.transport,_that.btAddress,_that.btName,_that.host,_that.port,_that.clientId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LinkTransport transport,  String btAddress,  String btName,  String host,  int port,  String clientId)?  $default,) {final _that = this;
switch (_that) {
case _BrokerSettings() when $default != null:
return $default(_that.transport,_that.btAddress,_that.btName,_that.host,_that.port,_that.clientId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrokerSettings extends BrokerSettings {
  const _BrokerSettings({this.transport = LinkTransport.bluetooth, this.btAddress = '', this.btName = '', required this.host, this.port = BrokerDefaults.port, required this.clientId}): super._();
  factory _BrokerSettings.fromJson(Map<String, dynamic> json) => _$BrokerSettingsFromJson(json);

@override@JsonKey() final  LinkTransport transport;
/// MAC address of the paired HC-05, e.g. `98:D3:31:F5:12:34`.
@override@JsonKey() final  String btAddress;
/// Name of the paired HC-05 (shown in the UI).
@override@JsonKey() final  String btName;
@override final  String host;
@override@JsonKey() final  int port;
@override final  String clientId;

/// Create a copy of BrokerSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrokerSettingsCopyWith<_BrokerSettings> get copyWith => __$BrokerSettingsCopyWithImpl<_BrokerSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrokerSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrokerSettings&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.btAddress, btAddress) || other.btAddress == btAddress)&&(identical(other.btName, btName) || other.btName == btName)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.clientId, clientId) || other.clientId == clientId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,transport,btAddress,btName,host,port,clientId);
}

@override
String toString() {
    return 'BrokerSettings(transport: $transport, btAddress: $btAddress, btName: $btName, host: $host, port: $port, clientId: $clientId)';
}


}

/// @nodoc
abstract mixin class _$BrokerSettingsCopyWith<$Res> implements $BrokerSettingsCopyWith<$Res> {
  factory _$BrokerSettingsCopyWith(_BrokerSettings value, $Res Function(_BrokerSettings) _then) = __$BrokerSettingsCopyWithImpl;
@override @useResult
$Res call({
 LinkTransport transport, String btAddress, String btName, String host, int port, String clientId
});




}
/// @nodoc
class __$BrokerSettingsCopyWithImpl<$Res>
    implements _$BrokerSettingsCopyWith<$Res> {
  __$BrokerSettingsCopyWithImpl(this._self, this._then);

  final _BrokerSettings _self;
  final $Res Function(_BrokerSettings) _then;

/// Create a copy of BrokerSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transport = null,Object? btAddress = null,Object? btName = null,Object? host = null,Object? port = null,Object? clientId = null,}) {
  return _then(_BrokerSettings(
transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as LinkTransport,btAddress: null == btAddress ? _self.btAddress : btAddress // ignore: cast_nullable_to_non_nullable
as String,btName: null == btName ? _self.btName : btName // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
