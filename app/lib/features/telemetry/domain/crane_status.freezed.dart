// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crane_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CraneStatus {

 bool get online;@JsonKey(name: 'fw') String? get firmware;/// Sensors / parts the crane has fitted (see [Sensor]); null = not reported (assume all fitted).
 List<String>? get sensors;
/// Create a copy of CraneStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CraneStatusCopyWith<CraneStatus> get copyWith => _$CraneStatusCopyWithImpl<CraneStatus>(this as CraneStatus, _$identity);

  /// Serializes this CraneStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CraneStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CraneStatus&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.firmware, _this.firmware) || other.firmware == _this.firmware)&&const DeepCollectionEquality().equals(other.sensors, _this.sensors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CraneStatus;
  return Object.hash(runtimeType,_this.online,_this.firmware,const DeepCollectionEquality().hash(_this.sensors));
}

@override
String toString() {
  final _this = this as CraneStatus;
  return 'CraneStatus(online: ${_this.online}, firmware: ${_this.firmware}, sensors: ${_this.sensors})';
}


}

/// @nodoc
abstract mixin class $CraneStatusCopyWith<$Res>  {
  factory $CraneStatusCopyWith(CraneStatus value, $Res Function(CraneStatus) _then) = _$CraneStatusCopyWithImpl;
@useResult
$Res call({
 bool online,@JsonKey(name: 'fw') String? firmware, List<String>? sensors
});




}
/// @nodoc
class _$CraneStatusCopyWithImpl<$Res>
    implements $CraneStatusCopyWith<$Res> {
  _$CraneStatusCopyWithImpl(this._self, this._then);

  final CraneStatus _self;
  final $Res Function(CraneStatus) _then;

/// Create a copy of CraneStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? online = null,Object? firmware = freezed,Object? sensors = freezed,}) {
  return _then(CraneStatus(
online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,firmware: freezed == firmware ? _self.firmware : firmware // ignore: cast_nullable_to_non_nullable
as String?,sensors: freezed == sensors ? _self.sensors : sensors // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CraneStatus].
extension CraneStatusPatterns on CraneStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CraneStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CraneStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CraneStatus value)  $default,){
final _that = this;
switch (_that) {
case _CraneStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CraneStatus value)?  $default,){
final _that = this;
switch (_that) {
case _CraneStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool online, @JsonKey(name: 'fw')  String? firmware,  List<String>? sensors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CraneStatus() when $default != null:
return $default(_that.online,_that.firmware,_that.sensors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool online, @JsonKey(name: 'fw')  String? firmware,  List<String>? sensors)  $default,) {final _that = this;
switch (_that) {
case _CraneStatus():
return $default(_that.online,_that.firmware,_that.sensors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool online, @JsonKey(name: 'fw')  String? firmware,  List<String>? sensors)?  $default,) {final _that = this;
switch (_that) {
case _CraneStatus() when $default != null:
return $default(_that.online,_that.firmware,_that.sensors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CraneStatus implements CraneStatus {
  const _CraneStatus({required this.online, @JsonKey(name: 'fw') this.firmware,  List<String>? sensors}): _sensors = sensors;
  factory _CraneStatus.fromJson(Map<String, dynamic> json) => _$CraneStatusFromJson(json);

@override final  bool online;
@override@JsonKey(name: 'fw') final  String? firmware;
/// Sensors / parts the crane has fitted (see [Sensor]); null = not reported (assume all fitted).
 final  List<String>? _sensors;
/// Sensors / parts the crane has fitted (see [Sensor]); null = not reported (assume all fitted).
@override List<String>? get sensors {
  final value = _sensors;
  if (value == null) return null;
  if (_sensors is EqualUnmodifiableListView) return _sensors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CraneStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CraneStatusCopyWith<_CraneStatus> get copyWith => __$CraneStatusCopyWithImpl<_CraneStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CraneStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CraneStatus&&(identical(other.online, online) || other.online == online)&&(identical(other.firmware, firmware) || other.firmware == firmware)&&const DeepCollectionEquality().equals(other.sensors, _sensors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,online,firmware,const DeepCollectionEquality().hash(_sensors));
}

@override
String toString() {
    return 'CraneStatus(online: $online, firmware: $firmware, sensors: $sensors)';
}


}

/// @nodoc
abstract mixin class _$CraneStatusCopyWith<$Res> implements $CraneStatusCopyWith<$Res> {
  factory _$CraneStatusCopyWith(_CraneStatus value, $Res Function(_CraneStatus) _then) = __$CraneStatusCopyWithImpl;
@override @useResult
$Res call({
 bool online,@JsonKey(name: 'fw') String? firmware, List<String>? sensors
});




}
/// @nodoc
class __$CraneStatusCopyWithImpl<$Res>
    implements _$CraneStatusCopyWith<$Res> {
  __$CraneStatusCopyWithImpl(this._self, this._then);

  final _CraneStatus _self;
  final $Res Function(_CraneStatus) _then;

/// Create a copy of CraneStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? online = null,Object? firmware = freezed,Object? sensors = freezed,}) {
  return _then(_CraneStatus(
online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,firmware: freezed == firmware ? _self.firmware : firmware // ignore: cast_nullable_to_non_nullable
as String?,sensors: freezed == sensors ? _self._sensors : sensors // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
