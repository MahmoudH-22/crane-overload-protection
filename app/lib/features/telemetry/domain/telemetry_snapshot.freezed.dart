// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'telemetry_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TelemetrySnapshot {

/// Last live sample (kept while stale so the UI can still show it greyed).
 CraneLive? get live;/// Arrival time of [live].
 DateTime? get lastLiveAt;/// Last `crane/status`.
 CraneStatus? get status;/// Weight over [Timing.chartWindow], oldest first.
 List<Sample> get weightHistory;/// Motor current over [Timing.sparklineWindow], oldest first.
 List<Sample> get currentHistory;
/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TelemetrySnapshotCopyWith<TelemetrySnapshot> get copyWith => _$TelemetrySnapshotCopyWithImpl<TelemetrySnapshot>(this as TelemetrySnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TelemetrySnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TelemetrySnapshot&&(identical(other.live, _this.live) || other.live == _this.live)&&(identical(other.lastLiveAt, _this.lastLiveAt) || other.lastLiveAt == _this.lastLiveAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.weightHistory, _this.weightHistory)&&const DeepCollectionEquality().equals(other.currentHistory, _this.currentHistory));
}


@override
int get hashCode {
  final _this = this as TelemetrySnapshot;
  return Object.hash(runtimeType,_this.live,_this.lastLiveAt,_this.status,const DeepCollectionEquality().hash(_this.weightHistory),const DeepCollectionEquality().hash(_this.currentHistory));
}

@override
String toString() {
  final _this = this as TelemetrySnapshot;
  return 'TelemetrySnapshot(live: ${_this.live}, lastLiveAt: ${_this.lastLiveAt}, status: ${_this.status}, weightHistory: ${_this.weightHistory}, currentHistory: ${_this.currentHistory})';
}


}

/// @nodoc
abstract mixin class $TelemetrySnapshotCopyWith<$Res>  {
  factory $TelemetrySnapshotCopyWith(TelemetrySnapshot value, $Res Function(TelemetrySnapshot) _then) = _$TelemetrySnapshotCopyWithImpl;
@useResult
$Res call({
 CraneLive? live, DateTime? lastLiveAt, CraneStatus? status, List<Sample> weightHistory, List<Sample> currentHistory
});


$CraneLiveCopyWith<$Res>? get live;$CraneStatusCopyWith<$Res>? get status;

}
/// @nodoc
class _$TelemetrySnapshotCopyWithImpl<$Res>
    implements $TelemetrySnapshotCopyWith<$Res> {
  _$TelemetrySnapshotCopyWithImpl(this._self, this._then);

  final TelemetrySnapshot _self;
  final $Res Function(TelemetrySnapshot) _then;

/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? live = freezed,Object? lastLiveAt = freezed,Object? status = freezed,Object? weightHistory = null,Object? currentHistory = null,}) {
  return _then(TelemetrySnapshot(
live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as CraneLive?,lastLiveAt: freezed == lastLiveAt ? _self.lastLiveAt : lastLiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CraneStatus?,weightHistory: null == weightHistory ? _self.weightHistory : weightHistory // ignore: cast_nullable_to_non_nullable
as List<Sample>,currentHistory: null == currentHistory ? _self.currentHistory : currentHistory // ignore: cast_nullable_to_non_nullable
as List<Sample>,
  ));
}
/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CraneLiveCopyWith<$Res>? get live {
    if (_self.live == null) {
    return null;
  }

  return $CraneLiveCopyWith<$Res>(_self.live!, (value) {
    return _then(_self.copyWith(live: value));
  });
}/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CraneStatusCopyWith<$Res>? get status {
    if (_self.status == null) {
    return null;
  }

  return $CraneStatusCopyWith<$Res>(_self.status!, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}


/// Adds pattern-matching-related methods to [TelemetrySnapshot].
extension TelemetrySnapshotPatterns on TelemetrySnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TelemetrySnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TelemetrySnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TelemetrySnapshot value)  $default,){
final _that = this;
switch (_that) {
case _TelemetrySnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TelemetrySnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _TelemetrySnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CraneLive? live,  DateTime? lastLiveAt,  CraneStatus? status,  List<Sample> weightHistory,  List<Sample> currentHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TelemetrySnapshot() when $default != null:
return $default(_that.live,_that.lastLiveAt,_that.status,_that.weightHistory,_that.currentHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CraneLive? live,  DateTime? lastLiveAt,  CraneStatus? status,  List<Sample> weightHistory,  List<Sample> currentHistory)  $default,) {final _that = this;
switch (_that) {
case _TelemetrySnapshot():
return $default(_that.live,_that.lastLiveAt,_that.status,_that.weightHistory,_that.currentHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CraneLive? live,  DateTime? lastLiveAt,  CraneStatus? status,  List<Sample> weightHistory,  List<Sample> currentHistory)?  $default,) {final _that = this;
switch (_that) {
case _TelemetrySnapshot() when $default != null:
return $default(_that.live,_that.lastLiveAt,_that.status,_that.weightHistory,_that.currentHistory);case _:
  return null;

}
}

}

/// @nodoc


class _TelemetrySnapshot extends TelemetrySnapshot {
  const _TelemetrySnapshot({this.live, this.lastLiveAt, this.status,  List<Sample> weightHistory = const <Sample>[],  List<Sample> currentHistory = const <Sample>[]}): _weightHistory = weightHistory,_currentHistory = currentHistory,super._();
  

/// Last live sample (kept while stale so the UI can still show it greyed).
@override final  CraneLive? live;
/// Arrival time of [live].
@override final  DateTime? lastLiveAt;
/// Last `crane/status`.
@override final  CraneStatus? status;
/// Weight over [Timing.chartWindow], oldest first.
 final  List<Sample> _weightHistory;
/// Weight over [Timing.chartWindow], oldest first.
@override@JsonKey() List<Sample> get weightHistory {
  if (_weightHistory is EqualUnmodifiableListView) return _weightHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weightHistory);
}

/// Motor current over [Timing.sparklineWindow], oldest first.
 final  List<Sample> _currentHistory;
/// Motor current over [Timing.sparklineWindow], oldest first.
@override@JsonKey() List<Sample> get currentHistory {
  if (_currentHistory is EqualUnmodifiableListView) return _currentHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_currentHistory);
}


/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TelemetrySnapshotCopyWith<_TelemetrySnapshot> get copyWith => __$TelemetrySnapshotCopyWithImpl<_TelemetrySnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TelemetrySnapshot&&(identical(other.live, live) || other.live == live)&&(identical(other.lastLiveAt, lastLiveAt) || other.lastLiveAt == lastLiveAt)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.weightHistory, _weightHistory)&&const DeepCollectionEquality().equals(other.currentHistory, _currentHistory));
}


@override
int get hashCode {
    return Object.hash(runtimeType,live,lastLiveAt,status,const DeepCollectionEquality().hash(_weightHistory),const DeepCollectionEquality().hash(_currentHistory));
}

@override
String toString() {
    return 'TelemetrySnapshot(live: $live, lastLiveAt: $lastLiveAt, status: $status, weightHistory: $weightHistory, currentHistory: $currentHistory)';
}


}

/// @nodoc
abstract mixin class _$TelemetrySnapshotCopyWith<$Res> implements $TelemetrySnapshotCopyWith<$Res> {
  factory _$TelemetrySnapshotCopyWith(_TelemetrySnapshot value, $Res Function(_TelemetrySnapshot) _then) = __$TelemetrySnapshotCopyWithImpl;
@override @useResult
$Res call({
 CraneLive? live, DateTime? lastLiveAt, CraneStatus? status, List<Sample> weightHistory, List<Sample> currentHistory
});


@override $CraneLiveCopyWith<$Res>? get live;@override $CraneStatusCopyWith<$Res>? get status;

}
/// @nodoc
class __$TelemetrySnapshotCopyWithImpl<$Res>
    implements _$TelemetrySnapshotCopyWith<$Res> {
  __$TelemetrySnapshotCopyWithImpl(this._self, this._then);

  final _TelemetrySnapshot _self;
  final $Res Function(_TelemetrySnapshot) _then;

/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? live = freezed,Object? lastLiveAt = freezed,Object? status = freezed,Object? weightHistory = null,Object? currentHistory = null,}) {
  return _then(_TelemetrySnapshot(
live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as CraneLive?,lastLiveAt: freezed == lastLiveAt ? _self.lastLiveAt : lastLiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CraneStatus?,weightHistory: null == weightHistory ? _self._weightHistory : weightHistory // ignore: cast_nullable_to_non_nullable
as List<Sample>,currentHistory: null == currentHistory ? _self._currentHistory : currentHistory // ignore: cast_nullable_to_non_nullable
as List<Sample>,
  ));
}

/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CraneLiveCopyWith<$Res>? get live {
    if (_self.live == null) {
    return null;
  }

  return $CraneLiveCopyWith<$Res>(_self.live!, (value) {
    return _then(_self.copyWith(live: value));
  });
}/// Create a copy of TelemetrySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CraneStatusCopyWith<$Res>? get status {
    if (_self.status == null) {
    return null;
  }

  return $CraneStatusCopyWith<$Res>(_self.status!, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

// dart format on
