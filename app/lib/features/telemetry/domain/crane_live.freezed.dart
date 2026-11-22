// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crane_live.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CraneLive {

/// Uno `millis()` when the sample was taken.
@JsonKey(name: 't') int get millis;/// Weight on the hook (tared), kg.
@JsonKey(name: 'kg') double get kg;/// Current overload limit, kg.
@JsonKey(name: 'max') double get maxKg;/// Hook height, mm (0 = table); null when the encoder is not fitted.
@JsonKey(name: 'h') double? get heightMm;/// Motor current, A; null when the current sensor is not fitted.
@JsonKey(name: 'a') double? get amps;/// IR top-of-travel sensor active.
 bool get top;/// Crane state.
@JsonKey(name: 'st', unknownEnumValue: CraneState.unknown) CraneState get state;/// LOCAL / REMOTE.
@JsonKey(unknownEnumValue: CraneMode.unknown) CraneMode get mode;/// Who started the current motion.
@JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown) MotionSource get source;/// Ultrasonic distance below the basket, mm (null = no echo / too close).
@JsonKey(name: 'us') double? get ultrasonicMm;/// Something is under the load (debounced on the Uno); lowering is blocked.
@JsonKey(name: 'obs') bool get obstacle;
/// Create a copy of CraneLive
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CraneLiveCopyWith<CraneLive> get copyWith => _$CraneLiveCopyWithImpl<CraneLive>(this as CraneLive, _$identity);

  /// Serializes this CraneLive to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CraneLive;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CraneLive&&(identical(other.millis, _this.millis) || other.millis == _this.millis)&&(identical(other.kg, _this.kg) || other.kg == _this.kg)&&(identical(other.maxKg, _this.maxKg) || other.maxKg == _this.maxKg)&&(identical(other.heightMm, _this.heightMm) || other.heightMm == _this.heightMm)&&(identical(other.amps, _this.amps) || other.amps == _this.amps)&&(identical(other.top, _this.top) || other.top == _this.top)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.ultrasonicMm, _this.ultrasonicMm) || other.ultrasonicMm == _this.ultrasonicMm)&&(identical(other.obstacle, _this.obstacle) || other.obstacle == _this.obstacle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CraneLive;
  return Object.hash(runtimeType,_this.millis,_this.kg,_this.maxKg,_this.heightMm,_this.amps,_this.top,_this.state,_this.mode,_this.source,_this.ultrasonicMm,_this.obstacle);
}

@override
String toString() {
  final _this = this as CraneLive;
  return 'CraneLive(millis: ${_this.millis}, kg: ${_this.kg}, maxKg: ${_this.maxKg}, heightMm: ${_this.heightMm}, amps: ${_this.amps}, top: ${_this.top}, state: ${_this.state}, mode: ${_this.mode}, source: ${_this.source}, ultrasonicMm: ${_this.ultrasonicMm}, obstacle: ${_this.obstacle})';
}


}

/// @nodoc
abstract mixin class $CraneLiveCopyWith<$Res>  {
  factory $CraneLiveCopyWith(CraneLive value, $Res Function(CraneLive) _then) = _$CraneLiveCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int millis,@JsonKey(name: 'kg') double kg,@JsonKey(name: 'max') double maxKg,@JsonKey(name: 'h') double? heightMm,@JsonKey(name: 'a') double? amps, bool top,@JsonKey(name: 'st', unknownEnumValue: CraneState.unknown) CraneState state,@JsonKey(unknownEnumValue: CraneMode.unknown) CraneMode mode,@JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown) MotionSource source,@JsonKey(name: 'us') double? ultrasonicMm,@JsonKey(name: 'obs') bool obstacle
});




}
/// @nodoc
class _$CraneLiveCopyWithImpl<$Res>
    implements $CraneLiveCopyWith<$Res> {
  _$CraneLiveCopyWithImpl(this._self, this._then);

  final CraneLive _self;
  final $Res Function(CraneLive) _then;

/// Create a copy of CraneLive
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? millis = null,Object? kg = null,Object? maxKg = null,Object? heightMm = freezed,Object? amps = freezed,Object? top = null,Object? state = null,Object? mode = null,Object? source = null,Object? ultrasonicMm = freezed,Object? obstacle = null,}) {
  return _then(CraneLive(
millis: null == millis ? _self.millis : millis // ignore: cast_nullable_to_non_nullable
as int,kg: null == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double,maxKg: null == maxKg ? _self.maxKg : maxKg // ignore: cast_nullable_to_non_nullable
as double,heightMm: freezed == heightMm ? _self.heightMm : heightMm // ignore: cast_nullable_to_non_nullable
as double?,amps: freezed == amps ? _self.amps : amps // ignore: cast_nullable_to_non_nullable
as double?,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as CraneState,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CraneMode,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as MotionSource,ultrasonicMm: freezed == ultrasonicMm ? _self.ultrasonicMm : ultrasonicMm // ignore: cast_nullable_to_non_nullable
as double?,obstacle: null == obstacle ? _self.obstacle : obstacle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CraneLive].
extension CraneLivePatterns on CraneLive {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CraneLive value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CraneLive() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CraneLive value)  $default,){
final _that = this;
switch (_that) {
case _CraneLive():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CraneLive value)?  $default,){
final _that = this;
switch (_that) {
case _CraneLive() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int millis, @JsonKey(name: 'kg')  double kg, @JsonKey(name: 'max')  double maxKg, @JsonKey(name: 'h')  double? heightMm, @JsonKey(name: 'a')  double? amps,  bool top, @JsonKey(name: 'st', unknownEnumValue: CraneState.unknown)  CraneState state, @JsonKey(unknownEnumValue: CraneMode.unknown)  CraneMode mode, @JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown)  MotionSource source, @JsonKey(name: 'us')  double? ultrasonicMm, @JsonKey(name: 'obs')  bool obstacle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CraneLive() when $default != null:
return $default(_that.millis,_that.kg,_that.maxKg,_that.heightMm,_that.amps,_that.top,_that.state,_that.mode,_that.source,_that.ultrasonicMm,_that.obstacle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int millis, @JsonKey(name: 'kg')  double kg, @JsonKey(name: 'max')  double maxKg, @JsonKey(name: 'h')  double? heightMm, @JsonKey(name: 'a')  double? amps,  bool top, @JsonKey(name: 'st', unknownEnumValue: CraneState.unknown)  CraneState state, @JsonKey(unknownEnumValue: CraneMode.unknown)  CraneMode mode, @JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown)  MotionSource source, @JsonKey(name: 'us')  double? ultrasonicMm, @JsonKey(name: 'obs')  bool obstacle)  $default,) {final _that = this;
switch (_that) {
case _CraneLive():
return $default(_that.millis,_that.kg,_that.maxKg,_that.heightMm,_that.amps,_that.top,_that.state,_that.mode,_that.source,_that.ultrasonicMm,_that.obstacle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int millis, @JsonKey(name: 'kg')  double kg, @JsonKey(name: 'max')  double maxKg, @JsonKey(name: 'h')  double? heightMm, @JsonKey(name: 'a')  double? amps,  bool top, @JsonKey(name: 'st', unknownEnumValue: CraneState.unknown)  CraneState state, @JsonKey(unknownEnumValue: CraneMode.unknown)  CraneMode mode, @JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown)  MotionSource source, @JsonKey(name: 'us')  double? ultrasonicMm, @JsonKey(name: 'obs')  bool obstacle)?  $default,) {final _that = this;
switch (_that) {
case _CraneLive() when $default != null:
return $default(_that.millis,_that.kg,_that.maxKg,_that.heightMm,_that.amps,_that.top,_that.state,_that.mode,_that.source,_that.ultrasonicMm,_that.obstacle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CraneLive implements CraneLive {
  const _CraneLive({@JsonKey(name: 't') this.millis = 0, @JsonKey(name: 'kg') required this.kg, @JsonKey(name: 'max') required this.maxKg, @JsonKey(name: 'h') this.heightMm, @JsonKey(name: 'a') this.amps, this.top = false, @JsonKey(name: 'st', unknownEnumValue: CraneState.unknown) required this.state, @JsonKey(unknownEnumValue: CraneMode.unknown) this.mode = CraneMode.unknown, @JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown) this.source = MotionSource.none, @JsonKey(name: 'us') this.ultrasonicMm, @JsonKey(name: 'obs') this.obstacle = false});
  factory _CraneLive.fromJson(Map<String, dynamic> json) => _$CraneLiveFromJson(json);

/// Uno `millis()` when the sample was taken.
@override@JsonKey(name: 't') final  int millis;
/// Weight on the hook (tared), kg.
@override@JsonKey(name: 'kg') final  double kg;
/// Current overload limit, kg.
@override@JsonKey(name: 'max') final  double maxKg;
/// Hook height, mm (0 = table); null when the encoder is not fitted.
@override@JsonKey(name: 'h') final  double? heightMm;
/// Motor current, A; null when the current sensor is not fitted.
@override@JsonKey(name: 'a') final  double? amps;
/// IR top-of-travel sensor active.
@override@JsonKey() final  bool top;
/// Crane state.
@override@JsonKey(name: 'st', unknownEnumValue: CraneState.unknown) final  CraneState state;
/// LOCAL / REMOTE.
@override@JsonKey(unknownEnumValue: CraneMode.unknown) final  CraneMode mode;
/// Who started the current motion.
@override@JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown) final  MotionSource source;
/// Ultrasonic distance below the basket, mm (null = no echo / too close).
@override@JsonKey(name: 'us') final  double? ultrasonicMm;
/// Something is under the load (debounced on the Uno); lowering is blocked.
@override@JsonKey(name: 'obs') final  bool obstacle;

/// Create a copy of CraneLive
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CraneLiveCopyWith<_CraneLive> get copyWith => __$CraneLiveCopyWithImpl<_CraneLive>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CraneLiveToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CraneLive&&(identical(other.millis, millis) || other.millis == millis)&&(identical(other.kg, kg) || other.kg == kg)&&(identical(other.maxKg, maxKg) || other.maxKg == maxKg)&&(identical(other.heightMm, heightMm) || other.heightMm == heightMm)&&(identical(other.amps, amps) || other.amps == amps)&&(identical(other.top, top) || other.top == top)&&(identical(other.state, state) || other.state == state)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.source, source) || other.source == source)&&(identical(other.ultrasonicMm, ultrasonicMm) || other.ultrasonicMm == ultrasonicMm)&&(identical(other.obstacle, obstacle) || other.obstacle == obstacle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,millis,kg,maxKg,heightMm,amps,top,state,mode,source,ultrasonicMm,obstacle);
}

@override
String toString() {
    return 'CraneLive(millis: $millis, kg: $kg, maxKg: $maxKg, heightMm: $heightMm, amps: $amps, top: $top, state: $state, mode: $mode, source: $source, ultrasonicMm: $ultrasonicMm, obstacle: $obstacle)';
}


}

/// @nodoc
abstract mixin class _$CraneLiveCopyWith<$Res> implements $CraneLiveCopyWith<$Res> {
  factory _$CraneLiveCopyWith(_CraneLive value, $Res Function(_CraneLive) _then) = __$CraneLiveCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int millis,@JsonKey(name: 'kg') double kg,@JsonKey(name: 'max') double maxKg,@JsonKey(name: 'h') double? heightMm,@JsonKey(name: 'a') double? amps, bool top,@JsonKey(name: 'st', unknownEnumValue: CraneState.unknown) CraneState state,@JsonKey(unknownEnumValue: CraneMode.unknown) CraneMode mode,@JsonKey(name: 'src', unknownEnumValue: MotionSource.unknown) MotionSource source,@JsonKey(name: 'us') double? ultrasonicMm,@JsonKey(name: 'obs') bool obstacle
});




}
/// @nodoc
class __$CraneLiveCopyWithImpl<$Res>
    implements _$CraneLiveCopyWith<$Res> {
  __$CraneLiveCopyWithImpl(this._self, this._then);

  final _CraneLive _self;
  final $Res Function(_CraneLive) _then;

/// Create a copy of CraneLive
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? millis = null,Object? kg = null,Object? maxKg = null,Object? heightMm = freezed,Object? amps = freezed,Object? top = null,Object? state = null,Object? mode = null,Object? source = null,Object? ultrasonicMm = freezed,Object? obstacle = null,}) {
  return _then(_CraneLive(
millis: null == millis ? _self.millis : millis // ignore: cast_nullable_to_non_nullable
as int,kg: null == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double,maxKg: null == maxKg ? _self.maxKg : maxKg // ignore: cast_nullable_to_non_nullable
as double,heightMm: freezed == heightMm ? _self.heightMm : heightMm // ignore: cast_nullable_to_non_nullable
as double?,amps: freezed == amps ? _self.amps : amps // ignore: cast_nullable_to_non_nullable
as double?,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as CraneState,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CraneMode,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as MotionSource,ultrasonicMm: freezed == ultrasonicMm ? _self.ultrasonicMm : ultrasonicMm // ignore: cast_nullable_to_non_nullable
as double?,obstacle: null == obstacle ? _self.obstacle : obstacle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
