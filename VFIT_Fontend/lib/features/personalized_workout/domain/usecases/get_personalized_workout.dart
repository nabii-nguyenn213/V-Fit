import '../entities/personalized_workout.dart';
import '../repositories/personalized_workout_repository.dart';

class GetPersonalizedWorkout {
  const GetPersonalizedWorkout(this._repository);

  final PersonalizedWorkoutRepository _repository;

  Future<PersonalizedWorkout> call({bool forceRefresh = false, bool isVip = false}) {
    return _repository.getPlan(forceRefresh: forceRefresh, isVip: isVip);
  }
}
