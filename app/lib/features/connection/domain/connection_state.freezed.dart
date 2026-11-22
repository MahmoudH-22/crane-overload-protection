// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BrokerConnection {

 BrokerStatus get status;/// User-readable error of the last failure.
 String? get error;/// When the current connection was established.
 DateTime? get connectedAt;/// Reconnect attempt number (1-based) while [BrokerStatus.reconnecting].
 int get attempt;/// Delay before the next reconnect attempt.
 Duration? get retryIn;
/// Create a copy of BrokerConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrokerConnectionCopyWith<BrokerConnection> get copyWith => _$BrokerConnectionCopyWithImpl<BrokerConnection>(this as BrokerConnection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BrokerConnection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrokerConnection&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.connectedAt, _this.connectedAt) || other.connectedAt == _this.connectedAt)&&(identical(other.attempt, _this.attempt) || other.attempt == _this.attempt)&&(identical(other.retryIn, _this.retryIn) || other.retryIn == _this.retryIn));
}


@override
int get hashCode {
  final _this = this as BrokerConnection;
  return Object.hash(runtimeType,_this.status,_this.error,_this.connectedAt,_this.attempt,_this.retryIn);
}

@override
String toString() {
  final _this = this as BrokerConnection;
  return 'BrokerConnection(status: ${_this.status}, error: ${_this.error}, connectedAt: ${_this.connectedAt}, attempt: ${_this.attempt}, retryIn: ${_this.retryIn})';
}


}

/// @nodoc
abstract mixin class $BrokerConnectionCopyWith<$Res>  {
  factory $BrokerConnectionCopyWith(BrokerConnection value, $Res Function(BrokerConnection) _then) = _$BrokerConnectionCopyWithImpl;
@useResult
$Res call({
 BrokerStatus status, String? error, DateTime? connectedAt, int attempt, Duration? retryIn
});




}
/// @nodoc
class _$BrokerConnectionCopyWithImpl<$Res>
    implements $BrokerConnectionCopyWith<$Res> {
  _$BrokerConnectionCopyWithImpl(this._self, this._then);

  final BrokerConnection _self;
  final $Res Function(BrokerConnection) _then;

/// Create a copy of BrokerConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? error = freezed,Object? connectedAt = freezed,Object? attempt = null,Object? retryIn = freezed,}) {
  return _then(BrokerConnection(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BrokerStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,connectedAt: freezed == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,retryIn: freezed == retryIn ? _self.retryIn : retryIn // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [BrokerConnection].
extension BrokerConnectionPatterns on BrokerConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrokerConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrokerConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrokerConnection value)  $default,){
final _that = this;
switch (_that) {
case _BrokerConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrokerConnection value)?  $default,){
final _that = this;
switch (_that) {
case _BrokerConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BrokerStatus status,  String? error,  DateTime? connectedAt,  int attempt,  Duration? retryIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrokerConnection() when $default != null:
return $default(_that.status,_that.error,_that.connectedAt,_that.attempt,_that.retryIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BrokerStatus status,  String? error,  DateTime? connectedAt,  int attempt,  Duration? retryIn)  $default,) {final _that = this;
switch (_that) {
case _BrokerConnection():
return $default(_that.status,_that.error,_that.connectedAt,_that.attempt,_that.retryIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BrokerStatus status,  String? error,  DateTime? connectedAt,  int attempt,  Duration? retryIn)?  $default,) {final _that = this;
switch (_that) {
case _BrokerConnection() when $default != null:
return $default(_that.status,_that.error,_that.connectedAt,_that.attempt,_that.retryIn);case _:
  return null;

}
}

}

/// @nodoc


class _BrokerConnection extends BrokerConnection {
  const _BrokerConnection({this.status = BrokerStatus.disconnected, this.error, this.connectedAt, this.attempt = 0, this.retryIn}): super._();
  

@override@JsonKey() final  BrokerStatus status;
/// User-readable error of the last failure.
@override final  String? error;
/// When the current connection was established.
@override final  DateTime? connectedAt;
/// Reconnect attempt number (1-based) while [BrokerStatus.reconnecting].
@override@JsonKey() final  int attempt;
/// Delay before the next reconnect attempt.
@override final  Duration? retryIn;

/// Create a copy of BrokerConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrokerConnectionCopyWith<_BrokerConnection> get copyWith => __$BrokerConnectionCopyWithImpl<_BrokerConnection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrokerConnection&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.connectedAt, connectedAt) || other.connectedAt == connectedAt)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.retryIn, retryIn) || other.retryIn == retryIn));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,error,connectedAt,attempt,retryIn);
}

@override
String toString() {
    return 'BrokerConnection(status: $status, error: $error, connectedAt: $connectedAt, attempt: $attempt, retryIn: $retryIn)';
}


}

/// @nodoc
abstract mixin class _$BrokerConnectionCopyWith<$Res> implements $BrokerConnectionCopyWith<$Res> {
  factory _$BrokerConnectionCopyWith(_BrokerConnection value, $Res Function(_BrokerConnection) _then) = __$BrokerConnectionCopyWithImpl;
@override @useResult
$Res call({
 BrokerStatus status, String? error, DateTime? connectedAt, int attempt, Duration? retryIn
});




}
/// @nodoc
class __$BrokerConnectionCopyWithImpl<$Res>
    implements _$BrokerConnectionCopyWith<$Res> {
  __$BrokerConnectionCopyWithImpl(this._self, this._then);

  final _BrokerConnection _self;
  final $Res Function(_BrokerConnection) _then;

/// Create a copy of BrokerConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? error = freezed,Object? connectedAt = freezed,Object? attempt = null,Object? retryIn = freezed,}) {
  return _then(_BrokerConnection(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BrokerStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,connectedAt: freezed == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,retryIn: freezed == retryIn ? _self.retryIn : retryIn // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
