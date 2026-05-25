import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/exercise_catalog.dart';
import '../../domain/repositories/exercise_library_repository.dart';
import '../../domain/usecases/get_exercise_catalog.dart';
import '../data_sources/exercise_library_local_data_source.dart';
import '../data_sources/exercise_library_remote_data_source.dart';

final exerciseLibraryRepositoryProvider =
    Provider<ExerciseLibraryRepository>((ref) {
  return ExerciseLibraryRepositoryImpl(
    remoteDataSource: ExerciseLibraryRemoteDataSource(ref.watch(dioProvider)),
    localDataSource: ExerciseLibraryLocalDataSource(),
  );
});

final getExerciseCatalogProvider = Provider<GetExerciseCatalog>((ref) {
  return GetExerciseCatalog(ref.watch(exerciseLibraryRepositoryProvider));
});

class ExerciseLibraryRepositoryImpl implements ExerciseLibraryRepository {
  const ExerciseLibraryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.cacheTtl = const Duration(days: 7),
  });

  final ExerciseLibraryRemoteDataSource remoteDataSource;
  final ExerciseLibraryLocalDataSource localDataSource;
  final Duration cacheTtl;

  @override
  Future<ExerciseCatalog> getGrouped({
    String locale = 'vi-VN',
    bool forceRefresh = false,
  }) async {
    final cached = await localDataSource.read();
    final hasUsableCache = cached != null && cached.catalog.groups.isNotEmpty;

    // Luôn fetch remote trước — cache chỉ là fallback khi mất mạng.
    // Điều này đảm bảo description mới nhất từ server luôn được hiển thị.
    try {
      final remote = await remoteDataSource.getGrouped(locale: locale);
      await localDataSource.write(remote);
      return remote;
    } on DioException {
      if (hasUsableCache) {
        return cached.catalog.copyWith(isStale: true);
      }
      rethrow;
    } catch (_) {
      if (hasUsableCache) {
        return cached.catalog.copyWith(isStale: true);
      }
      rethrow;
    }
  }

}
