import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/enum_parsers.dart';
import '../../../auth/application/auth_controller.dart';
import '../models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final bodyMetricsProvider = FutureProvider.autoDispose<BodyMetricModel>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.user;
  if (user == null || user.onboardingStatus != OnboardingStatus.completed) {
    return const BodyMetricModel();
  }
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

  Future<UserModel> uploadAvatar(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      
      final mimeType = file.mimeType;
      MediaType mediaType;
      if (mimeType != null && mimeType.startsWith('image/')) {
        final parts = mimeType.split('/');
        mediaType = MediaType(parts.first, parts.length > 1 ? parts.last : 'jpeg');
      } else {
        final lowerName = file.name.toLowerCase();
        if (lowerName.endsWith('.png')) {
          mediaType = MediaType('image', 'png');
        } else if (lowerName.endsWith('.webp')) {
          mediaType = MediaType('image', 'webp');
        } else {
          mediaType = MediaType('image', 'jpeg');
        }
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: mediaType,
        ),
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

  Future<void> deleteAccount() async {
    try {
      final response = await _dio.delete<dynamic>(ApiEndpoints.deleteAccount);
      ApiResponseParser.unwrapVoid(response);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
