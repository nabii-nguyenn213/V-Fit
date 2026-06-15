import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/network_providers.dart';

final aiPlannersRepositoryProvider = Provider<AiPlannersRepository>((ref) {
  final dio = ref.watch(aiDioProvider);
  return AiPlannersRepository(dio);
});

class AiPlannersRepository {
  final Dio _dio;

  AiPlannersRepository(this._dio);

  /// POST /api/v1/workout-planner/
  Future<Map<String, dynamic>> createWorkoutPlan({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String goal,
    required String activityLevel,
    required String level,
    required int daysPerWeek,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/workout-planner/',
      data: {
        'age': age,
        'gender': gender,
        'weight': weight,
        'height': height,
        'goal': goal,
        'activity_level': activityLevel,
        'level': level,
        'days_per_week': daysPerWeek,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }
    throw Exception('Không thể tạo lịch tập từ AI.');
  }

  /// POST /api/v1/meal-planner/
  Future<Map<String, dynamic>> createMealPlan({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String goal,
    required String activityLevel,
    required int mealsPerDay,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/meal-planner/',
      data: {
        'age': age,
        'gender': gender,
        'weight': weight,
        'height': height,
        'goal': goal,
        'activity_level': activityLevel,
        'meals_per_day': mealsPerDay,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }
    throw Exception('Không thể tạo thực đơn từ AI.');
  }

  /// POST /api/v1/food-scanner/text
  Future<Map<String, dynamic>> scanFoodText({
    required String foodName,
    required String portion,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/food-scanner/text',
      data: {
        'food_name': foodName,
        'portion': portion,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }
    throw Exception('Không thể phân tích dinh dưỡng món ăn.');
  }

  /// POST /api/v1/food-scanner/
  Future<Map<String, dynamic>> scanFoodImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/food-scanner/',
      data: formData,
      options: Options(
        extra: {
          'vfitFormDataBytes': bytes,
          'vfitFormDataFilename': filename,
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }
    throw Exception('Không thể phân tích ảnh món ăn.');
  }
}
