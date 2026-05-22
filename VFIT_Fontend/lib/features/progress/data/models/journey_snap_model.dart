import 'package:freezed_annotation/freezed_annotation.dart';

part 'journey_snap_model.freezed.dart';
part 'journey_snap_model.g.dart';

@freezed
class JourneySnapModel with _$JourneySnapModel {
  const factory JourneySnapModel({
    required String id,
    required String photoUrl,
    String? note,
    required DateTime createdAt,
  }) = _JourneySnapModel;

  factory JourneySnapModel.fromJson(Map<String, dynamic> json) =>
      _$JourneySnapModelFromJson(json);
}
