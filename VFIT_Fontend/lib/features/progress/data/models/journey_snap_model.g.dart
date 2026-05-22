// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_snap_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JourneySnapModelImpl _$$JourneySnapModelImplFromJson(
        Map<String, dynamic> json) =>
    _$JourneySnapModelImpl(
      id: json['id'] as String,
      photoUrl: json['photoUrl'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$JourneySnapModelImplToJson(
        _$JourneySnapModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'photoUrl': instance.photoUrl,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };
