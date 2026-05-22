import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../models/exercise_catalog_model.dart';

class ExerciseLibraryRemoteDataSource {
  const ExerciseLibraryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ExerciseCatalogModel> getGrouped({String locale = 'vi-VN'}) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.groupedExercises,
      queryParameters: {'locale': locale},
    );
    return ApiResponseParser.unwrap(
      response,
      (json) => ExerciseCatalogModel.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }
}
