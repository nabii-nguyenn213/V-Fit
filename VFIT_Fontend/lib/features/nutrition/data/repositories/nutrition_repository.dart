import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../models/food_calorie_estimate_model.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(dioProvider));
});

class NutritionRepository {
  const NutritionRepository(this._dio);

  final Dio _dio;

  Future<FoodCalorieEstimateModel> estimateFoodCalories() async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.foodCalorieEstimate,
        data: FormData(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => FoodCalorieEstimateModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
