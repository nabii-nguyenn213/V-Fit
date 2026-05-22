import '../entities/exercise_catalog.dart';

abstract class ExerciseLibraryRepository {
  Future<ExerciseCatalog> getGrouped({
    String locale = 'vi-VN',
    bool forceRefresh = false,
  });
}
