import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../profile/data/models/user_model.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(dioProvider));
});

class OnboardingRepository {
  const OnboardingRepository(this._dio);

  final Dio _dio;

  Future<UserModel> updatePhysicalProfile({
    required double heightCm,
    required double weightKg,
    double? bodyFatPercent,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.onboardingProfile,
        data: {
          'heightCm': heightCm,
          'weightKg': weightKg,
          if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
        },
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserModel> completeBodyScan(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.uri.pathSegments.isEmpty
              ? 'body-scan.jpg'
              : file.uri.pathSegments.last,
        ),
      });
      final response = await _dio.post<dynamic>(
        ApiEndpoints.onboardingBodyScan,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      return ApiResponseParser.unwrap(response, (json) {
        final data = Map<String, dynamic>.from(json as Map);
        return UserModel.fromJson(
          Map<String, dynamic>.from(data['user'] as Map),
        );
      });
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserModel> completeRealtimeBodyScan(
      Map<String, dynamic> bodyAnalysisResult) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.onboardingRealtime,
        data: bodyAnalysisResult,
      );
      return ApiResponseParser.unwrap(response, (json) {
        final data = Map<String, dynamic>.from(json as Map);
        return UserModel.fromJson(
          Map<String, dynamic>.from(data['user'] as Map),
        );
      });
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
