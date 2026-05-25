import 'package:equatable/equatable.dart';

sealed class PersonalizedWorkoutEvent extends Equatable {
  const PersonalizedWorkoutEvent();

  @override
  List<Object?> get props => [];
}

class PersonalizedWorkoutRequested extends PersonalizedWorkoutEvent {
  const PersonalizedWorkoutRequested({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}
