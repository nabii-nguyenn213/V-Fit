import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../models/checkin_models.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return CheckinRepository(ref.watch(dioProvider));
});

class CheckinRepository {
  const CheckinRepository(this._dio);

  final Dio _dio;

  Future<CheckinResult> checkinToday() async {
    try {
      final response = await _dio.post<dynamic>(ApiEndpoints.checkin);
      return ApiResponseParser.unwrap(
        response,
        (json) =>
            CheckinResult.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CheckinStatus> getCheckinStatus() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.checkinStatus);
      return ApiResponseParser.unwrap(
        response,
        (json) =>
            CheckinStatus.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
