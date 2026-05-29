import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/token_storage.dart';

final workoutCheckinRepositoryProvider =
    Provider<WorkoutCheckinRepository>((ref) {
  return WorkoutCheckinRepository(ref.watch(dioProvider), appTokenStorage);
});

class WorkoutCheckinRepository {
  const WorkoutCheckinRepository(this._dio, [this._tokenStorage]);

  final Dio _dio;
  final TokenStorage? _tokenStorage;

  /// Notifies the backend that the user has completed all exercises for today.
  /// Backend will increment the streak on every active challenge participation.
  Future<void> logWorkoutDayComplete() async {
    try {
      final options = await _authorizedOptions();
      await _dio.post<dynamic>(
        '/api/gamification/challenges/workout-checkin',
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Options> _authorizedOptions() async {
    final storage = _tokenStorage ?? appTokenStorage;
    final token = await storage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Phiên đăng nhập đã hết hạn.',
        statusCode: 401,
      );
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
