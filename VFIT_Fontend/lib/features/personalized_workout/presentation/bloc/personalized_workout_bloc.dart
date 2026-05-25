import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_error_mapper.dart';
import '../../../../core/error/crash_reporter.dart';
import '../../domain/usecases/get_personalized_workout.dart';
import 'personalized_workout_event.dart';
import 'personalized_workout_state.dart';

class PersonalizedWorkoutBloc
    extends Bloc<PersonalizedWorkoutEvent, PersonalizedWorkoutState> {
  PersonalizedWorkoutBloc(this._getPersonalizedWorkout)
      : super(const WorkoutInitial()) {
    on<PersonalizedWorkoutRequested>(_onRequested);
  }

  final GetPersonalizedWorkout _getPersonalizedWorkout;

  Future<void> _onRequested(
    PersonalizedWorkoutRequested event,
    Emitter<PersonalizedWorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());
    try {
      final plan = await _getPersonalizedWorkout(
        forceRefresh: event.forceRefresh,
      );
      if (plan.hasGoal) {
        emit(WorkoutLoaded(plan: plan));
      } else {
        emit(const WorkoutUnconfigured());
      }
    } catch (error, stackTrace) {
      await CrashReporter.record(error, stackTrace);
      emit(
        WorkoutUnconfigured(
          errorMessage: AppErrorMapper.friendlyMessage(error),
        ),
      );
    }
  }
}
