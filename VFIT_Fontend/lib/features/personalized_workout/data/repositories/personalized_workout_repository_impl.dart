import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/personalized_workout.dart';
import '../../domain/repositories/personalized_workout_repository.dart';
import '../../domain/usecases/get_personalized_workout.dart';
import '../data_sources/personalized_workout_local_source.dart';
import '../data_sources/personalized_workout_remote_source.dart';

final personalizedWorkoutRepositoryProvider =
    Provider<PersonalizedWorkoutRepository>((ref) {
  return PersonalizedWorkoutRepositoryImpl(
    remoteDataSource: PersonalizedWorkoutRemoteDataSource(ref.watch(dioProvider)),
    localDataSource: PersonalizedWorkoutLocalDataSource(),
  );
});

final getPersonalizedWorkoutProvider = Provider<GetPersonalizedWorkout>((ref) {
  return GetPersonalizedWorkout(ref.watch(personalizedWorkoutRepositoryProvider));
});

class PersonalizedWorkoutRepositoryImpl implements PersonalizedWorkoutRepository {
  const PersonalizedWorkoutRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final PersonalizedWorkoutRemoteDataSource remoteDataSource;
  final PersonalizedWorkoutLocalDataSource localDataSource;

  @override
  Future<PersonalizedWorkout> getPlan({bool forceRefresh = false}) async {
    final cached = await localDataSource.read();
    final hasUsableCache = cached != null;

    // Luôn fetch remote trước — cache chỉ là fallback khi mất mạng hoặc kết nối yếu.
    try {
      final remote = await remoteDataSource.getPlan();
      await localDataSource.write(remote);
      return remote;
    } on DioException {
      if (hasUsableCache) {
        return cached.workout.copyWith(isStale: true);
      }
      rethrow;
    } catch (_) {
      if (hasUsableCache) {
        return cached.workout.copyWith(isStale: true);
      }
      rethrow;
    }
  }
}
