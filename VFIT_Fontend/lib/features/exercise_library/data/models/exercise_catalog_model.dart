import '../../domain/entities/exercise_catalog.dart';

class ExerciseCatalogModel extends ExerciseCatalog {
  const ExerciseCatalogModel({
    required super.catalogVersion,
    required super.groups,
    super.isStale,
  });

  factory ExerciseCatalogModel.fromJson(Map<String, dynamic> json) {
    return ExerciseCatalogModel(
      catalogVersion: (json['catalogVersion'] as num?)?.toInt() ?? 0,
      groups: (json['groups'] as List? ?? const [])
          .whereType<Map>()
          .map((item) =>
              MuscleGroupModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalogVersion': catalogVersion,
      'groups': groups
          .whereType<MuscleGroupModel>()
          .map((group) => group.toJson())
          .toList(),
    };
  }
}

class MuscleGroupModel extends MuscleGroup {
  const MuscleGroupModel({
    required super.id,
    required super.name,
    required super.subGroups,
  });

  factory MuscleGroupModel.fromJson(Map<String, dynamic> json) {
    return MuscleGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      subGroups: (json['subGroups'] as List? ?? const [])
          .whereType<Map>()
          .map((item) =>
              SubMuscleGroupModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subGroups': subGroups
          .whereType<SubMuscleGroupModel>()
          .map((subGroup) => subGroup.toJson())
          .toList(),
    };
  }
}

class SubMuscleGroupModel extends SubMuscleGroup {
  const SubMuscleGroupModel({
    required super.id,
    required super.name,
    required super.exercises,
  });

  factory SubMuscleGroupModel.fromJson(Map<String, dynamic> json) {
    return SubMuscleGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      exercises: (json['exercises'] as List? ?? const [])
          .whereType<Map>()
          .map((item) =>
              ExerciseItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises
          .whereType<ExerciseItemModel>()
          .map((exercise) => exercise.toJson())
          .toList(),
    };
  }
}

class ExerciseItemModel extends ExerciseItem {
  const ExerciseItemModel({
    required super.id,
    required super.name,
    required super.equipment,
    super.videoUrl,
    super.videoSearchHint,
    super.description,
  });

  factory ExerciseItemModel.fromJson(Map<String, dynamic> json) {
    return ExerciseItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString(),
      videoSearchHint: json['videoSearchHint']?.toString(),
      description: json['description']?.toString(),
      equipment: (json['equipment'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (videoSearchHint != null) 'videoSearchHint': videoSearchHint,
      if (description != null) 'description': description,
      'equipment': equipment,
    };
  }
}
