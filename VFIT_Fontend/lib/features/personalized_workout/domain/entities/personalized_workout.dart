import 'package:equatable/equatable.dart';
import '../../../../core/utils/enum_parsers.dart';

class PersonalizedWorkout extends Equatable {
  const PersonalizedWorkout({
    required this.hasGoal,
    this.goalType,
    this.rules,
    this.nutritionRecovery,
    this.schedule,
    this.isStale = false,
  });

  final bool hasGoal;
  final GoalType? goalType;
  final WorkoutRules? rules;
  final NutritionRecovery? nutritionRecovery;
  final Map<int, DaySchedule>? schedule;
  final bool isStale;

  PersonalizedWorkout copyWith({
    bool? hasGoal,
    GoalType? goalType,
    WorkoutRules? rules,
    NutritionRecovery? nutritionRecovery,
    Map<int, DaySchedule>? schedule,
    bool? isStale,
  }) {
    return PersonalizedWorkout(
      hasGoal: hasGoal ?? this.hasGoal,
      goalType: goalType ?? this.goalType,
      rules: rules ?? this.rules,
      nutritionRecovery: nutritionRecovery ?? this.nutritionRecovery,
      schedule: schedule ?? this.schedule,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [hasGoal, goalType, rules, nutritionRecovery, schedule, isStale];
}

class WorkoutRules extends Equatable {
  const WorkoutRules({
    required this.compound,
    required this.isolation,
  });

  final RuleDetail compound;
  final RuleDetail isolation;

  @override
  List<Object?> get props => [compound, isolation];
}

class RuleDetail extends Equatable {
  const RuleDetail({
    required this.reps,
    required this.rest,
    required this.rir,
  });

  final String reps;
  final String rest;
  final String rir;

  @override
  List<Object?> get props => [reps, rest, rir];
}

class NutritionRecovery extends Equatable {
  const NutritionRecovery({
    required this.caloriesTarget,
    required this.proteinTarget,
    required this.weightTarget,
    required this.sleepTarget,
    this.waterTarget,
  });

  final String caloriesTarget;
  final String proteinTarget;
  final String weightTarget;
  final String sleepTarget;
  final String? waterTarget;

  @override
  List<Object?> get props => [caloriesTarget, proteinTarget, weightTarget, sleepTarget, waterTarget];
}

class DaySchedule extends Equatable {
  const DaySchedule({
    required this.dayName,
    required this.dayType,
    required this.restDay,
    required this.exercises,
    this.cardioAfterWorkout,
  });

  final String dayName;
  final String dayType;
  final bool restDay;
  final List<ExerciseItemMetadata> exercises;
  final String? cardioAfterWorkout;

  @override
  List<Object?> get props => [dayName, dayType, restDay, exercises, cardioAfterWorkout];
}

class ExerciseItemMetadata extends Equatable {
  const ExerciseItemMetadata({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.notes,
  });

  final String exerciseId;
  final int sets;
  final String reps;
  final String? notes;

  @override
  List<Object?> get props => [exerciseId, sets, reps, notes];
}
