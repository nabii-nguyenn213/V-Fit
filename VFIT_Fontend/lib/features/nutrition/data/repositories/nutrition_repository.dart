import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<FoodCalorieEstimateModel> estimateFoodCalories(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final response = await _dio.post<dynamic>(
        ApiEndpoints.foodCalorieEstimate,
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(
            bytes,
            filename: image.name,
            contentType: _contentTypeFor(image),
          ),
        }),
        options: Options(contentType: Headers.multipartFormDataContentType),
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

  MediaType _contentTypeFor(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) {
      final parts = mimeType.split('/');
      return MediaType(parts.first, parts.length > 1 ? parts.last : 'jpeg');
    }
    final lowerName = image.name.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lowerName.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}
