import '../entities/exercise_catalog.dart';
import '../repositories/exercise_library_repository.dart';

class GetExerciseCatalog {
  const GetExerciseCatalog(this._repository);

  final ExerciseLibraryRepository _repository;

  Future<ExerciseCatalog> call({
    String locale = 'vi-VN',
    bool forceRefresh = false,
  }) {
    return _repository.getGrouped(
      locale: locale,
      forceRefresh: forceRefresh,
    );
  }
}
