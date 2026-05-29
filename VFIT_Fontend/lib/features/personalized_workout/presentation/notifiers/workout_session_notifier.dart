import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../challenges/data/repositories/challenge_repository.dart';
import '../../data/repositories/workout_checkin_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.exerciseIds,
    required this.doneSet,
    this.lastDoneAt,
    this.isSubmitting = false,
    this.submitted = false,
  });

  /// Ordered list of exercise IDs for the current day.
  final List<String> exerciseIds;

  /// IDs that have been ticked done.
  final Set<String> doneSet;

  /// Timestamp of the most recent tick. Used to enforce the 5-min cooldown.
  final DateTime? lastDoneAt;

  final bool isSubmitting;

  /// True once the backend has acknowledged the completed workout day.
  final bool submitted;

  bool get allDone =>
      exerciseIds.isNotEmpty && doneSet.length >= exerciseIds.length;

  bool isDone(String id) => doneSet.contains(id);

  /// Returns null when the next tick is allowed, or remaining [Duration] to wait.
  Duration? cooldownRemaining() {
    if (lastDoneAt == null) return null;
    final elapsed = DateTime.now().difference(lastDoneAt!);
    const required = Duration(minutes: 1);
    if (elapsed >= required) return null;
    return required - elapsed;
  }

  WorkoutSessionState copyWith({
    List<String>? exerciseIds,
    Set<String>? doneSet,
    DateTime? lastDoneAt,
    bool? isSubmitting,
    bool? submitted,
  }) {
    return WorkoutSessionState(
      exerciseIds: exerciseIds ?? this.exerciseIds,
      doneSet: doneSet ?? this.doneSet,
      lastDoneAt: lastDoneAt ?? this.lastDoneAt,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitted: submitted ?? this.submitted,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionNotifier({
    required List<String> exerciseIds,
    required WorkoutCheckinRepository checkinRepo,
    required Ref ref,
  })  : _checkinRepo = checkinRepo,
        _ref = ref,
        super(WorkoutSessionState(
          exerciseIds: exerciseIds,
          doneSet: const {},
        ));

  final WorkoutCheckinRepository _checkinRepo;
  final Ref _ref;

  // ------------------------------------------------------------------
  // Mark an exercise done (with cooldown guard)
  // ------------------------------------------------------------------

  /// Returns true if the tick was accepted, false if blocked by cooldown.
  bool markDone(String exerciseId) {
    if (state.isDone(exerciseId)) return true; // already done — no-op

    final remaining = state.cooldownRemaining();
    if (remaining != null) return false; // cooldown still active

    final newDone = {...state.doneSet, exerciseId};
    state = state.copyWith(doneSet: newDone, lastDoneAt: DateTime.now());

    if (state.allDone) {
      _submitWorkoutComplete();
    }

    return true;
  }

  // ------------------------------------------------------------------
  // Backend submission
  // ------------------------------------------------------------------

  Future<void> _submitWorkoutComplete() async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _checkinRepo.logWorkoutDayComplete();
      state = state.copyWith(isSubmitting: false, submitted: true);
      // Refresh challenge data so the Progress tab updates
      _ref.invalidate(activeParticipationsProvider);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      // Non-fatal — streak will sync on next app open
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// One notifier per day view. Pass [exerciseIds] for the selected day.
/// Scoped to `autoDispose` so state resets when the user navigates away.
final workoutSessionProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionNotifier, WorkoutSessionState, List<String>>(
  (ref, exerciseIds) => WorkoutSessionNotifier(
    exerciseIds: exerciseIds,
    checkinRepo: ref.watch(workoutCheckinRepositoryProvider),
    ref: ref,
  ),
);
