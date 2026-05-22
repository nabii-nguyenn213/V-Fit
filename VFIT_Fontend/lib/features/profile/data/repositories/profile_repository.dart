import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final bodyMetricsProvider = FutureProvider.autoDispose<BodyMetricModel>((ref) {
  return ref.watch(profileRepositoryProvider).bodyMetrics();
});

class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.me,
        data: request.toJson(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserModel> uploadAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await _dio.post<dynamic>(
        ApiEndpoints.avatar,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      ApiResponseParser.unwrapVoid(response);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<BodyMetricModel> bodyMetrics() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.bodyMetrics);
      return ApiResponseParser.unwrap(
        response,
        (json) =>
            BodyMetricModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
