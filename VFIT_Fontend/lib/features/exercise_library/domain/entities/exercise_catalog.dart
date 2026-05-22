import 'package:equatable/equatable.dart';

class ExerciseCatalog extends Equatable {
  const ExerciseCatalog({
    required this.catalogVersion,
    required this.groups,
    this.isStale = false,
  });

  final int catalogVersion;
  final List<MuscleGroup> groups;
  final bool isStale;

  ExerciseCatalog copyWith({bool? isStale}) {
    return ExerciseCatalog(
      catalogVersion: catalogVersion,
      groups: groups,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [catalogVersion, groups, isStale];
}

class MuscleGroup extends Equatable {
  const MuscleGroup({
    required this.id,
    required this.name,
    required this.subGroups,
  });

  final String id;
  final String name;
  final List<SubMuscleGroup> subGroups;

  int get exerciseCount => subGroups.fold<int>(
        0,
        (total, subGroup) => total + subGroup.exercises.length,
      );

  @override
  List<Object?> get props => [id, name, subGroups];
}

class SubMuscleGroup extends Equatable {
  const SubMuscleGroup({
    required this.id,
    required this.name,
    required this.exercises,
  });

  final String id;
  final String name;
  final List<ExerciseItem> exercises;

  @override
  List<Object?> get props => [id, name, exercises];
}

class ExerciseItem extends Equatable {
  const ExerciseItem({
    required this.id,
    required this.name,
    required this.equipment,
    this.videoUrl,
    this.videoSearchHint,
    this.description,
  });

  final String id;
  final String name;
  final String? videoUrl;
  final String? videoSearchHint;
  final String? description;
  final List<String> equipment;

  @override
  List<Object?> get props => [
        id,
        name,
        videoUrl,
        videoSearchHint,
        description,
        equipment,
      ];
}
