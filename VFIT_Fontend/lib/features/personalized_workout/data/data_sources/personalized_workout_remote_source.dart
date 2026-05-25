import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../models/personalized_workout_model.dart';

class PersonalizedWorkoutRemoteDataSource {
  const PersonalizedWorkoutRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PersonalizedWorkoutModel> getPlan() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.personalizedWorkout,
    );
    return ApiResponseParser.unwrap(
      response,
      (json) => PersonalizedWorkoutModel.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }
}
