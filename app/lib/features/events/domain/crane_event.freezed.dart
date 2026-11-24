// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crane_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CraneEvent {

/// Uno `millis()` of the event.
@JsonKey(name: 't') int get millis;/// Event type.
@JsonKey(unknownEnumValue: CraneEventType.unknown) CraneEventType get type;/// Weight at the event (new limit for MAX_CHANGED), kg.
 double? get kg;/// When the app received it (not part of the payload).
@JsonKey(includeFromJson: false, includeToJson: false) DateTime? get receivedAt;
/// Create a copy of CraneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CraneEventCopyWith<CraneEvent> get copyWith => _$CraneEventCopyWithImpl<CraneEvent>(this as CraneEvent, _$identity);

  /// Serializes this CraneEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CraneEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CraneEvent&&(identical(other.millis, _this.millis) || other.millis == _this.millis)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.kg, _this.kg) || other.kg == _this.kg)&&(identical(other.receivedAt, _this.receivedAt) || other.receivedAt == _this.receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CraneEvent;
  return Object.hash(runtimeType,_this.millis,_this.type,_this.kg,_this.receivedAt);
}

@override
String toString() {
  final _this = this as CraneEvent;
  return 'CraneEvent(millis: ${_this.millis}, type: ${_this.type}, kg: ${_this.kg}, receivedAt: ${_this.receivedAt})';
}


}

/// @nodoc
abstract mixin class $CraneEventCopyWith<$Res>  {
  factory $CraneEventCopyWith(CraneEvent value, $Res Function(CraneEvent) _then) = _$CraneEventCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int millis,@JsonKey(unknownEnumValue: CraneEventType.unknown) CraneEventType type, double? kg,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? receivedAt
});




}
/// @nodoc
class _$CraneEventCopyWithImpl<$Res>
    implements $CraneEventCopyWith<$Res> {
  _$CraneEventCopyWithImpl(this._self, this._then);

  final CraneEvent _self;
  final $Res Function(CraneEvent) _then;

/// Create a copy of CraneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? millis = null,Object? type = null,Object? kg = freezed,Object? receivedAt = freezed,}) {
  return _then(CraneEvent(
millis: null == millis ? _self.millis : millis // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CraneEventType,kg: freezed == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double?,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CraneEvent].
extension CraneEventPatterns on CraneEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CraneEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CraneEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CraneEvent value)  $default,){
final _that = this;
switch (_that) {
case _CraneEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CraneEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CraneEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int millis, @JsonKey(unknownEnumValue: CraneEventType.unknown)  CraneEventType type,  double? kg, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? receivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CraneEvent() when $default != null:
return $default(_that.millis,_that.type,_that.kg,_that.receivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int millis, @JsonKey(unknownEnumValue: CraneEventType.unknown)  CraneEventType type,  double? kg, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? receivedAt)  $default,) {final _that = this;
switch (_that) {
case _CraneEvent():
return $default(_that.millis,_that.type,_that.kg,_that.receivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int millis, @JsonKey(unknownEnumValue: CraneEventType.unknown)  CraneEventType type,  double? kg, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? receivedAt)?  $default,) {final _that = this;
switch (_that) {
case _CraneEvent() when $default != null:
return $default(_that.millis,_that.type,_that.kg,_that.receivedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CraneEvent implements CraneEvent {
  const _CraneEvent({@JsonKey(name: 't') this.millis = 0, @JsonKey(unknownEnumValue: CraneEventType.unknown) required this.type, this.kg, @JsonKey(includeFromJson: false, includeToJson: false) this.receivedAt});
  factory _CraneEvent.fromJson(Map<String, dynamic> json) => _$CraneEventFromJson(json);

/// Uno `millis()` of the event.
@override@JsonKey(name: 't') final  int millis;
/// Event type.
@override@JsonKey(unknownEnumValue: CraneEventType.unknown) final  CraneEventType type;
/// Weight at the event (new limit for MAX_CHANGED), kg.
@override final  double? kg;
/// When the app received it (not part of the payload).
@override@JsonKey(includeFromJson: false, includeToJson: false) final  DateTime? receivedAt;

/// Create a copy of CraneEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CraneEventCopyWith<_CraneEvent> get copyWith => __$CraneEventCopyWithImpl<_CraneEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CraneEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CraneEvent&&(identical(other.millis, millis) || other.millis == millis)&&(identical(other.type, type) || other.type == type)&&(identical(other.kg, kg) || other.kg == kg)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,millis,type,kg,receivedAt);
}

@override
String toString() {
    return 'CraneEvent(millis: $millis, type: $type, kg: $kg, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class _$CraneEventCopyWith<$Res> implements $CraneEventCopyWith<$Res> {
  factory _$CraneEventCopyWith(_CraneEvent value, $Res Function(_CraneEvent) _then) = __$CraneEventCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int millis,@JsonKey(unknownEnumValue: CraneEventType.unknown) CraneEventType type, double? kg,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? receivedAt
});




}
/// @nodoc
class __$CraneEventCopyWithImpl<$Res>
    implements _$CraneEventCopyWith<$Res> {
  __$CraneEventCopyWithImpl(this._self, this._then);

  final _CraneEvent _self;
  final $Res Function(_CraneEvent) _then;

/// Create a copy of CraneEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? millis = null,Object? type = null,Object? kg = freezed,Object? receivedAt = freezed,}) {
  return _then(_CraneEvent(
millis: null == millis ? _self.millis : millis // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CraneEventType,kg: freezed == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double?,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
