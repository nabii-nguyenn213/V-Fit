import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/enum_parsers.dart';
import '../models/exercise_model.dart';
import '../models/workout_program_model.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(dioProvider));
});

final workoutProgramsProvider =
    FutureProvider.autoDispose<PageResponse<WorkoutProgramModel>>((ref) {
  return ref.watch(workoutRepositoryProvider).programs();
});

final workoutProgramProvider =
    FutureProvider.autoDispose.family<WorkoutProgramModel, String>((ref, id) {
  return ref.watch(workoutRepositoryProvider).program(id);
});

final exerciseQueryProvider =
    StateProvider.autoDispose<ExerciseQuery>((ref) => const ExerciseQuery());

final exercisesProvider = FutureProvider.autoDispose
    .family<PageResponse<ExerciseModel>, ExerciseQuery>(
  (ref, query) {
    return ref.watch(workoutRepositoryProvider).exercises(query);
  },
);

final exerciseProvider =
    FutureProvider.autoDispose.family<ExerciseModel, String>((ref, id) {
  return ref.watch(workoutRepositoryProvider).exercise(id);
});

class ExerciseQuery {
  const ExerciseQuery({
    this.keyword,
    this.muscleGroup,
    this.difficulty,
    this.page = 0,
    this.size = AppConstants.defaultPageSize,
  });

  final String? keyword;
  final String? muscleGroup;
  final DifficultyLevel? difficulty;
  final int page;
  final int size;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (keyword != null && keyword!.trim().isNotEmpty)
        'keyword': keyword!.trim(),
      if (muscleGroup != null && muscleGroup!.trim().isNotEmpty)
        'muscleGroup': muscleGroup!.trim(),
      if (difficulty != null) 'difficulty': difficultyLevelToJson(difficulty!),
      'page': page,
      'size': size,
    };
  }

  ExerciseQuery copyWith({
    String? keyword,
    String? muscleGroup,
    DifficultyLevel? difficulty,
    int? page,
    int? size,
    bool clearDifficulty = false,
  }) {
    return ExerciseQuery(
      keyword: keyword ?? this.keyword,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      difficulty: clearDifficulty ? null : difficulty ?? this.difficulty,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseQuery &&
        other.keyword == keyword &&
        other.muscleGroup == muscleGroup &&
        other.difficulty == difficulty &&
        other.page == page &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(keyword, muscleGroup, difficulty, page, size);
}

class WorkoutRepository {
  const WorkoutRepository(this._dio);

  final Dio _dio;

  Future<PageResponse<WorkoutProgramModel>> programs() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.workouts,
        queryParameters: const {
          'page': 0,
          'size': AppConstants.defaultPageSize
        },
      );
      return ApiResponseParser.unwrapPage(
          response, WorkoutProgramModel.fromJson);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<WorkoutProgramModel> program(String id) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.workout(id));
      return ApiResponseParser.unwrap(
        response,
        (json) => WorkoutProgramModel.fromJson(
            Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PageResponse<ExerciseModel>> exercises(ExerciseQuery query) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.exercises,
        queryParameters: query.toQueryParameters(),
      );
      return ApiResponseParser.unwrapPage(response, ExerciseModel.fromJson);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ExerciseModel> exercise(String id) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.exercise(id));
      return ApiResponseParser.unwrap(
        response,
        (json) =>
            ExerciseModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
