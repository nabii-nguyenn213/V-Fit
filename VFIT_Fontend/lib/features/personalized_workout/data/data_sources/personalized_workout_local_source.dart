import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/personalized_workout_model.dart';

class CachedPersonalizedWorkout {
  const CachedPersonalizedWorkout({
    required this.workout,
    required this.cachedAt,
  });

  final PersonalizedWorkoutModel workout;
  final DateTime cachedAt;

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(cachedAt) < ttl;
  }
}

class PersonalizedWorkoutLocalDataSource {
  static const _boxName = 'personalized_workout_cache';
  static const _planJsonKey = 'plan_json';
  static const _cachedAtMsKey = 'cached_at_ms';

  Future<CachedPersonalizedWorkout?> read() async {
    final box = await Hive.openBox<String>(_boxName);
    final json = box.get(_planJsonKey);
    final cachedAtRaw = box.get(_cachedAtMsKey);
    final cachedAtMs = int.tryParse(cachedAtRaw ?? '');
    
    if (json == null || cachedAtMs == null) {
      return null;
    }

    try {
      final workoutModel = PersonalizedWorkoutModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(json) as Map),
      );
      return CachedPersonalizedWorkout(
        workout: workoutModel,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(PersonalizedWorkoutModel plan) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_planJsonKey, jsonEncode(plan.toJson()));
    await box.put(
      _cachedAtMsKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> clear() async {
    final box = await Hive.openBox<String>(_boxName);
    await box.clear();
  }
}
