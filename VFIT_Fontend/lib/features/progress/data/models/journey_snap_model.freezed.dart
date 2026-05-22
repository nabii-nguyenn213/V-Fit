// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journey_snap_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JourneySnapModel _$JourneySnapModelFromJson(Map<String, dynamic> json) {
  return _JourneySnapModel.fromJson(json);
}

/// @nodoc
mixin _$JourneySnapModel {
  String get id => throw _privateConstructorUsedError;
  String get photoUrl => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this JourneySnapModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JourneySnapModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JourneySnapModelCopyWith<JourneySnapModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JourneySnapModelCopyWith<$Res> {
  factory $JourneySnapModelCopyWith(
          JourneySnapModel value, $Res Function(JourneySnapModel) then) =
      _$JourneySnapModelCopyWithImpl<$Res, JourneySnapModel>;
  @useResult
  $Res call({String id, String photoUrl, String? note, DateTime createdAt});
}

/// @nodoc
class _$JourneySnapModelCopyWithImpl<$Res, $Val extends JourneySnapModel>
    implements $JourneySnapModelCopyWith<$Res> {
  _$JourneySnapModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JourneySnapModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? photoUrl = null,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: null == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JourneySnapModelImplCopyWith<$Res>
    implements $JourneySnapModelCopyWith<$Res> {
  factory _$$JourneySnapModelImplCopyWith(_$JourneySnapModelImpl value,
          $Res Function(_$JourneySnapModelImpl) then) =
      __$$JourneySnapModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String photoUrl, String? note, DateTime createdAt});
}

/// @nodoc
class __$$JourneySnapModelImplCopyWithImpl<$Res>
    extends _$JourneySnapModelCopyWithImpl<$Res, _$JourneySnapModelImpl>
    implements _$$JourneySnapModelImplCopyWith<$Res> {
  __$$JourneySnapModelImplCopyWithImpl(_$JourneySnapModelImpl _value,
      $Res Function(_$JourneySnapModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of JourneySnapModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? photoUrl = null,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$JourneySnapModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: null == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JourneySnapModelImpl implements _JourneySnapModel {
  const _$JourneySnapModelImpl(
      {required this.id,
      required this.photoUrl,
      this.note,
      required this.createdAt});

  factory _$JourneySnapModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$JourneySnapModelImplFromJson(json);

  @override
  final String id;
  @override
  final String photoUrl;
  @override
  final String? note;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'JourneySnapModel(id: $id, photoUrl: $photoUrl, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JourneySnapModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, photoUrl, note, createdAt);

  /// Create a copy of JourneySnapModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JourneySnapModelImplCopyWith<_$JourneySnapModelImpl> get copyWith =>
      __$$JourneySnapModelImplCopyWithImpl<_$JourneySnapModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JourneySnapModelImplToJson(
      this,
    );
  }
}

abstract class _JourneySnapModel implements JourneySnapModel {
  const factory _JourneySnapModel(
      {required final String id,
      required final String photoUrl,
      final String? note,
      required final DateTime createdAt}) = _$JourneySnapModelImpl;

  factory _JourneySnapModel.fromJson(Map<String, dynamic> json) =
      _$JourneySnapModelImpl.fromJson;

  @override
  String get id;
  @override
  String get photoUrl;
  @override
  String? get note;
  @override
  DateTime get createdAt;

  /// Create a copy of JourneySnapModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JourneySnapModelImplCopyWith<_$JourneySnapModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
