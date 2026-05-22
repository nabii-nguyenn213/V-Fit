import '../../../../core/utils/enum_parsers.dart';

class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.difficulty,
    required this.instructions,
    this.videoUrl,
    this.thumbnailUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final DifficultyLevel difficulty;
  final List<String> instructions;
  final String? videoUrl;
  final String? thumbnailUrl;
  final DateTime? createdAt;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      muscleGroup: json['muscleGroup']?.toString() ?? '',
      difficulty: difficultyLevelFromJson(json['difficulty']?.toString()),
      instructions:
          (json['instructions'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      videoUrl: json['videoUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
