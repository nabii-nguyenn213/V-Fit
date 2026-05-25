import 'package:equatable/equatable.dart';
import '../../domain/entities/personalized_workout.dart';

sealed class PersonalizedWorkoutState extends Equatable {
  const PersonalizedWorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends PersonalizedWorkoutState {
  const WorkoutInitial();
}

class WorkoutLoading extends PersonalizedWorkoutState {
  const WorkoutLoading();
}

class WorkoutUnconfigured extends PersonalizedWorkoutState {
  const WorkoutUnconfigured({this.errorMessage});
  final String? errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}

class WorkoutLoaded extends PersonalizedWorkoutState {
  const WorkoutLoaded({required this.plan, this.errorMessage});
  final PersonalizedWorkout plan;
  final String? errorMessage;

  @override
  List<Object?> get props => [plan, errorMessage];
}
