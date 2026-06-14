import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/personalized_workout.dart';
import '../../domain/repositories/personalized_workout_repository.dart';
import '../../domain/usecases/get_personalized_workout.dart';
import '../data_sources/personalized_workout_local_source.dart';
import '../data_sources/personalized_workout_remote_source.dart';
import '../models/personalized_workout_model.dart';

final personalizedWorkoutRepositoryProvider =
    Provider<PersonalizedWorkoutRepository>((ref) {
  return PersonalizedWorkoutRepositoryImpl(
    remoteDataSource: PersonalizedWorkoutRemoteDataSource(ref.watch(dioProvider)),
    localDataSource: PersonalizedWorkoutLocalDataSource(),
  );
});

final getPersonalizedWorkoutProvider = Provider<GetPersonalizedWorkout>((ref) {
  return GetPersonalizedWorkout(ref.watch(personalizedWorkoutRepositoryProvider));
});

class PersonalizedWorkoutRepositoryImpl implements PersonalizedWorkoutRepository {
  const PersonalizedWorkoutRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final PersonalizedWorkoutRemoteDataSource remoteDataSource;
  final PersonalizedWorkoutLocalDataSource localDataSource;

  @override
  Future<PersonalizedWorkout> getPlan({bool forceRefresh = false}) async {
    final isAiApplied = await localDataSource.isAiApplied();
    if (isAiApplied) {
      final cached = await localDataSource.read();
      if (cached != null) {
        return cached.workout;
      }
    }

    final cached = await localDataSource.read();
    final hasUsableCache = cached != null;

    // Luôn fetch remote trước — cache chỉ là fallback khi mất mạng hoặc kết nối yếu.
    try {
      final remote = await remoteDataSource.getPlan();
      await localDataSource.write(remote);
      return remote;
    } on DioException {
      if (hasUsableCache) {
        return cached.workout.copyWith(isStale: true);
      }
      rethrow;
    } catch (_) {
      if (hasUsableCache) {
        return cached.workout.copyWith(isStale: true);
      }
      rethrow;
    }
  }

  @override
  Future<void> applyAiPlan(PersonalizedWorkout plan) async {
    final model = PersonalizedWorkoutModel(
      hasGoal: plan.hasGoal,
      goalType: plan.goalType,
      rules: plan.rules != null
          ? WorkoutRulesModel(
              compound: RuleDetailModel(
                reps: plan.rules!.compound.reps,
                rest: plan.rules!.compound.rest,
                rir: plan.rules!.compound.rir,
              ),
              isolation: RuleDetailModel(
                reps: plan.rules!.isolation.reps,
                rest: plan.rules!.isolation.rest,
                rir: plan.rules!.isolation.rir,
              ),
            )
          : null,
      nutritionRecovery: plan.nutritionRecovery != null
          ? NutritionRecoveryModel(
              caloriesTarget: plan.nutritionRecovery!.caloriesTarget,
              proteinTarget: plan.nutritionRecovery!.proteinTarget,
              weightTarget: plan.nutritionRecovery!.weightTarget,
              sleepTarget: plan.nutritionRecovery!.sleepTarget,
              waterTarget: plan.nutritionRecovery!.waterTarget,
            )
          : null,
      schedule: plan.schedule != null
          ? plan.schedule!.map((key, value) {
              return MapEntry(
                key,
                DayScheduleModel(
                  dayName: value.dayName,
                  dayType: value.dayType,
                  restDay: value.restDay,
                  exercises: value.exercises
                      .map((e) => ExerciseItemMetadataModel(
                            exerciseId: e.exerciseId,
                            sets: e.sets,
                            reps: e.reps,
                            notes: e.notes,
                          ))
                      .toList(),
                  cardioAfterWorkout: value.cardioAfterWorkout,
                ),
              );
            })
          : null,
    );
    await localDataSource.writeAiPlan(model);
  }

  @override
  Future<bool> isAiPlanApplied() async {
    return localDataSource.isAiApplied();
  }
}
