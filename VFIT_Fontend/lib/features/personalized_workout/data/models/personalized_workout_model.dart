import '../../../../core/utils/enum_parsers.dart';
import '../../domain/entities/personalized_workout.dart';

class PersonalizedWorkoutModel extends PersonalizedWorkout {
  const PersonalizedWorkoutModel({
    required super.hasGoal,
    super.goalType,
    super.rules,
    super.nutritionRecovery,
    super.schedule,
    super.isStale,
  });

  factory PersonalizedWorkoutModel.fromJson(Map<String, dynamic> json) {
    final hasGoal = json['hasGoal'] as bool? ?? false;
    if (!hasGoal) {
      return const PersonalizedWorkoutModel(hasGoal: false);
    }

    final rawGoalType = json['goalType']?.toString();
    final goalType = goalTypeFromJson(rawGoalType);

    final rawRules = json['rules'] as Map<String, dynamic>?;
    final rules = rawRules != null ? WorkoutRulesModel.fromJson(rawRules) : null;

    final rawNutrition = json['nutritionRecovery'] as Map<String, dynamic>?;
    final nutrition = rawNutrition != null ? NutritionRecoveryModel.fromJson(rawNutrition) : null;

    final rawSchedule = json['schedule'] as Map<String, dynamic>?;
    final schedule = rawSchedule != null
        ? rawSchedule.map((key, value) {
            final intKey = int.tryParse(key) ?? 1;
            return MapEntry(
              intKey,
              DayScheduleModel.fromJson(Map<String, dynamic>.from(value as Map)),
            );
          })
        : null;

    return PersonalizedWorkoutModel(
      hasGoal: hasGoal,
      goalType: goalType,
      rules: rules,
      nutritionRecovery: nutrition,
      schedule: schedule,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasGoal': hasGoal,
      if (goalType != null) 'goalType': goalTypeToJson(goalType),
      if (rules != null) 'rules': (rules as WorkoutRulesModel).toJson(),
      if (nutritionRecovery != null)
        'nutritionRecovery': (nutritionRecovery as NutritionRecoveryModel).toJson(),
      if (schedule != null)
        'schedule': schedule!.map((key, value) {
          return MapEntry(
            key.toString(),
            (value as DayScheduleModel).toJson(),
          );
        }),
    };
  }
}

class WorkoutRulesModel extends WorkoutRules {
  const WorkoutRulesModel({
    required super.compound,
    required super.isolation,
  });

  factory WorkoutRulesModel.fromJson(Map<String, dynamic> json) {
    return WorkoutRulesModel(
      compound: RuleDetailModel.fromJson(
        Map<String, dynamic>.from(json['compound'] as Map),
      ),
      isolation: RuleDetailModel.fromJson(
        Map<String, dynamic>.from(json['isolation'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compound': (compound as RuleDetailModel).toJson(),
      'isolation': (isolation as RuleDetailModel).toJson(),
    };
  }
}

class RuleDetailModel extends RuleDetail {
  const RuleDetailModel({
    required super.reps,
    required super.rest,
    required super.rir,
  });

  factory RuleDetailModel.fromJson(Map<String, dynamic> json) {
    return RuleDetailModel(
      reps: json['reps']?.toString() ?? '',
      rest: json['rest']?.toString() ?? '',
      rir: json['rir']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'rest': rest,
      'rir': rir,
    };
  }
}

class NutritionRecoveryModel extends NutritionRecovery {
  const NutritionRecoveryModel({
    required super.caloriesTarget,
    required super.proteinTarget,
    required super.weightTarget,
    required super.sleepTarget,
    super.waterTarget,
  });

  factory NutritionRecoveryModel.fromJson(Map<String, dynamic> json) {
    return NutritionRecoveryModel(
      caloriesTarget: json['caloriesTarget']?.toString() ?? '',
      proteinTarget: json['proteinTarget']?.toString() ?? '',
      weightTarget: json['weightTarget']?.toString() ?? '',
      sleepTarget: json['sleepTarget']?.toString() ?? '',
      waterTarget: json['waterTarget']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caloriesTarget': caloriesTarget,
      'proteinTarget': proteinTarget,
      'weightTarget': weightTarget,
      'sleepTarget': sleepTarget,
      if (waterTarget != null) 'waterTarget': waterTarget,
    };
  }
}

class DayScheduleModel extends DaySchedule {
  const DayScheduleModel({
    required super.dayName,
    required super.dayType,
    required super.restDay,
    required super.exercises,
    super.cardioAfterWorkout,
  });

  factory DayScheduleModel.fromJson(Map<String, dynamic> json) {
    return DayScheduleModel(
      dayName: json['dayName']?.toString() ?? '',
      dayType: json['dayType']?.toString() ?? '',
      restDay: json['restDay'] as bool? ?? false,
      cardioAfterWorkout: json['cardioAfterWorkout']?.toString(),
      exercises: (json['exercises'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => ExerciseItemMetadataModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'dayType': dayType,
      'restDay': restDay,
      if (cardioAfterWorkout != null) 'cardioAfterWorkout': cardioAfterWorkout,
      'exercises': exercises
          .whereType<ExerciseItemMetadataModel>()
          .map((item) => item.toJson())
          .toList(),
    };
  }
}

class ExerciseItemMetadataModel extends ExerciseItemMetadata {
  const ExerciseItemMetadataModel({
    required super.exerciseId,
    required super.sets,
    required super.reps,
    super.notes,
  });

  factory ExerciseItemMetadataModel.fromJson(Map<String, dynamic> json) {
    return ExerciseItemMetadataModel(
      exerciseId: json['exerciseId']?.toString() ?? '',
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      reps: json['reps']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      if (notes != null) 'notes': notes,
    };
  }
}
