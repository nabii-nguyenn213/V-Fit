import '../../../../core/utils/enum_parsers.dart';

class WorkoutProgramModel {
  const WorkoutProgramModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.durationMinutes,
    required this.exerciseIds,
    this.description,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final DifficultyLevel difficulty;
  final int durationMinutes;
  final List<String> exerciseIds;
  final DateTime? createdAt;

  factory WorkoutProgramModel.fromJson(Map<String, dynamic> json) {
    return WorkoutProgramModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      difficulty: difficultyLevelFromJson(json['difficulty']?.toString()),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      exerciseIds:
          (json['exerciseIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
