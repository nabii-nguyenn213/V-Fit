import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/exercise_catalog_model.dart';

class CachedExerciseCatalog {
  const CachedExerciseCatalog({
    required this.catalog,
    required this.cachedAt,
  });

  final ExerciseCatalogModel catalog;
  final DateTime cachedAt;

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(cachedAt) < ttl;
  }
}

class ExerciseLibraryLocalDataSource {
  static const _boxName = 'exercise_library_cache';
  static const _catalogJsonKey = 'catalog_json';
  static const _cachedAtMsKey = 'cached_at_ms';

  Future<CachedExerciseCatalog?> read() async {
    final box = await Hive.openBox<String>(_boxName);
    final json = box.get(_catalogJsonKey);
    final cachedAtRaw = box.get(_cachedAtMsKey);
    final cachedAtMs = int.tryParse(cachedAtRaw ?? '');
    if (json == null || cachedAtMs == null) {
      return null;
    }
    return CachedExerciseCatalog(
      catalog: ExerciseCatalogModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(json) as Map),
      ),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
    );
  }

  Future<void> write(ExerciseCatalogModel catalog) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_catalogJsonKey, jsonEncode(catalog.toJson()));
    await box.put(
      _cachedAtMsKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}
