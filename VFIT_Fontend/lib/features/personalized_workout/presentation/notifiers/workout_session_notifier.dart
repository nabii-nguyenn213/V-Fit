import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/network_providers.dart';
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

  /// Timestamp of the most recent tick. Used to enforce the 1-min cooldown.
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

  Map<String, dynamic> toJson() {
    return {
      'doneSet': doneSet.toList(),
      'lastDoneAt': lastDoneAt?.toIso8601String(),
      'submitted': submitted,
    };
  }

  factory WorkoutSessionState.fromJson(
      Map<String, dynamic> json, List<String> exerciseIds) {
    return WorkoutSessionState(
      exerciseIds: exerciseIds,
      doneSet:
          (json['doneSet'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      lastDoneAt: json['lastDoneAt'] != null
          ? DateTime.parse(json['lastDoneAt'] as String)
          : null,
      submitted: json['submitted'] as bool? ?? false,
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
    required SharedPreferences prefs,
    required Ref ref,
  })  : _checkinRepo = checkinRepo,
        _prefs = prefs,
        _ref = ref,
        super(_loadInitialState(exerciseIds, prefs));

  final WorkoutCheckinRepository _checkinRepo;
  final SharedPreferences _prefs;
  final Ref _ref;

  /// Generate a unique storage key for today's session.
  /// Format: workout_session_YYYY_M_D
  static String get _storageKey {
    final now = DateTime.now();
    return 'workout_session_${now.year}_${now.month}_${now.day}';
  }

  static WorkoutSessionState _loadInitialState(
      List<String> exerciseIds, SharedPreferences prefs) {
    final data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return WorkoutSessionState.fromJson(json, exerciseIds);
      } catch (_) {}
    }
    return WorkoutSessionState(exerciseIds: exerciseIds, doneSet: const {});
  }

  void _saveState() {
    _prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

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
    
    // Persist immediately
    _saveState();

    if (state.allDone && !state.submitted) {
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
      _saveState(); // Save submitted state
      
      // Refresh challenge data so the Progress tab updates
      _ref.invalidate(activeParticipationsProvider);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      // Non-fatal — streak will sync on next app open
    }
  }
  
  /// Helper method for testing: clears today's session completely.
  void debugClearSession() {
    _prefs.remove(_storageKey);
    state = WorkoutSessionState(exerciseIds: state.exerciseIds, doneSet: const {});
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// One notifier per day view. Pass [exerciseIds] for the selected day.
/// Scoped to `autoDispose` so state resets when the user navigates away,
/// but state is backed by SharedPreferences so it survives app restarts.
final workoutSessionProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionNotifier, WorkoutSessionState, List<String>>(
  (ref, exerciseIds) => WorkoutSessionNotifier(
    exerciseIds: exerciseIds,
    checkinRepo: ref.watch(workoutCheckinRepositoryProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    ref: ref,
  ),
);
