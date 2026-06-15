import '../../domain/entities/personalized_workout.dart';

abstract class PersonalizedWorkoutRepository {
  Future<PersonalizedWorkout> getPlan({bool forceRefresh = false, bool isVip = false});
  Future<void> applyAiPlan(PersonalizedWorkout plan);
  Future<bool> isAiPlanApplied();
  Future<void> revertAiPlan();
}
