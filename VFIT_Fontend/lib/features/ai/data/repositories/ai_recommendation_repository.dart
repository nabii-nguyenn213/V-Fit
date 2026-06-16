import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';

final aiRecommendationRepositoryProvider =
    Provider<AiRecommendationRepository>((ref) {
  return AiRecommendationRepository(ref.watch(aiDioProvider));
});

class AiRecommendationRepository {
  const AiRecommendationRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> askCoach(
    Map<String, dynamic> payload,
  ) {
    return _post(ApiEndpoints.aiCoach, payload);
  }

  Future<Map<String, dynamic>> createWorkoutPlan(
    Map<String, dynamic> payload,
  ) {
    return _post(ApiEndpoints.aiWorkoutPlanner, payload);
  }

  Future<Map<String, dynamic>> createMealPlan(
    Map<String, dynamic> payload,
  ) {
    return _post(ApiEndpoints.aiMealPlanner, payload);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      print('[AI RECOMMENDATION] POST $path payload=$payload');

      final response = await _dio.post<dynamic>(
        path,
        data: payload,
      );

      final result = ApiResponseParser.unwrap(response, (json) {
        if (json is! Map) {
          throw const ApiException(
            message: 'Invalid AI response',
          );
        }

        return Map<String, dynamic>.from(json);
      });

      print(
        '[AI RECOMMENDATION] $path response=$result',
      );

      return result;
    } on DioException catch (error) {
      print(
        '[AI RECOMMENDATION] $path failed '
        'status=${error.response?.statusCode} '
        'body=${error.response?.data}',
      );

      throw ApiException.fromDio(error);
    }
  }
}