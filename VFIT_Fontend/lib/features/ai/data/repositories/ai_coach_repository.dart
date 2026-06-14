import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';

final aiCoachRepositoryProvider = Provider<AiCoachRepository>((ref) {
  final dio = ref.watch(aiDioProvider);
  return AiCoachRepository(dio);
});

class AiCoachRepository {
  final Dio _dio;

  AiCoachRepository(this._dio);

  Future<String> askCoach({
    required String question,
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String goal,
    required String activityLevel,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/coach/',
      data: {
        'question': question,
        'age': age,
        'gender': gender,
        'weight': weight,
        'height': height,
        'goal': goal,
        'activity_level': activityLevel,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final answer = response.data!['answer'] as String?;
      if (answer != null) {
        return answer;
      }
    }
    throw Exception('Không nhận được phản hồi từ AI Coach.');
  }
}
