// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_ack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommandAck {

 int get id; bool get ok; String? get reason;
/// Create a copy of CommandAck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandAckCopyWith<CommandAck> get copyWith => _$CommandAckCopyWithImpl<CommandAck>(this as CommandAck, _$identity);

  /// Serializes this CommandAck to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommandAck;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandAck&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommandAck;
  return Object.hash(runtimeType,_this.id,_this.ok,_this.reason);
}

@override
String toString() {
  final _this = this as CommandAck;
  return 'CommandAck(id: ${_this.id}, ok: ${_this.ok}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $CommandAckCopyWith<$Res>  {
  factory $CommandAckCopyWith(CommandAck value, $Res Function(CommandAck) _then) = _$CommandAckCopyWithImpl;
@useResult
$Res call({
 int id, bool ok, String? reason
});




}
/// @nodoc
class _$CommandAckCopyWithImpl<$Res>
    implements $CommandAckCopyWith<$Res> {
  _$CommandAckCopyWithImpl(this._self, this._then);

  final CommandAck _self;
  final $Res Function(CommandAck) _then;

/// Create a copy of CommandAck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ok = null,Object? reason = freezed,}) {
  return _then(CommandAck(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommandAck].
extension CommandAckPatterns on CommandAck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommandAck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommandAck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommandAck value)  $default,){
final _that = this;
switch (_that) {
case _CommandAck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommandAck value)?  $default,){
final _that = this;
switch (_that) {
case _CommandAck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  bool ok,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommandAck() when $default != null:
return $default(_that.id,_that.ok,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  bool ok,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _CommandAck():
return $default(_that.id,_that.ok,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  bool ok,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _CommandAck() when $default != null:
return $default(_that.id,_that.ok,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommandAck extends CommandAck {
  const _CommandAck({required this.id, required this.ok, this.reason}): super._();
  factory _CommandAck.fromJson(Map<String, dynamic> json) => _$CommandAckFromJson(json);

@override final  int id;
@override final  bool ok;
@override final  String? reason;

/// Create a copy of CommandAck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommandAckCopyWith<_CommandAck> get copyWith => __$CommandAckCopyWithImpl<_CommandAck>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommandAckToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommandAck&&(identical(other.id, id) || other.id == id)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,ok,reason);
}

@override
String toString() {
    return 'CommandAck(id: $id, ok: $ok, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$CommandAckCopyWith<$Res> implements $CommandAckCopyWith<$Res> {
  factory _$CommandAckCopyWith(_CommandAck value, $Res Function(_CommandAck) _then) = __$CommandAckCopyWithImpl;
@override @useResult
$Res call({
 int id, bool ok, String? reason
});




}
/// @nodoc
class __$CommandAckCopyWithImpl<$Res>
    implements _$CommandAckCopyWith<$Res> {
  __$CommandAckCopyWithImpl(this._self, this._then);

  final _CommandAck _self;
  final $Res Function(_CommandAck) _then;

/// Create a copy of CommandAck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ok = null,Object? reason = freezed,}) {
  return _then(_CommandAck(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
