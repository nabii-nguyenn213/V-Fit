import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../../profile/data/models/user_model.dart';
import '../models/auth_models.dart';
import '../services/social_login_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    appTokenStorage,
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.login,
        data: request.toJson(),
      );
      final auth = ApiResponseParser.unwrap(
        response,
        (json) => AuthResponse.fromJson(Map<String, dynamic>.from(json as Map)),
      );
      await _persistTokens(auth.tokens);
      return auth;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthResponse> socialLogin(SocialLoginCredential credential) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[AuthRepository] POST ${ApiEndpoints.socialLogin} '
          'provider=${credential.provider.name} platform=${credential.platform}',
        );
      }
      final response = await _dio.post<dynamic>(
        ApiEndpoints.socialLogin,
        data: SocialLoginRequest(
          provider: credential.provider,
          providerToken: credential.providerToken,
          platform: credential.platform,
        ).toJson(),
      );
      final auth = ApiResponseParser.unwrap(
        response,
        (json) => AuthResponse.fromJson(Map<String, dynamic>.from(json as Map)),
      );
      await _persistTokens(auth.tokens);
      return auth;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.register,
        data: request.toJson(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.resendOtp,
        data: {
          'email': email.trim(),
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.verifyOtp,
        data: {
          'email': email.trim(),
          'otpCode': otpCode.trim(),
        },
      );
      final auth = ApiResponseParser.unwrap(
        response,
        (json) => AuthResponse.fromJson(Map<String, dynamic>.from(json as Map)),
      );
      await _persistTokens(auth.tokens);
      return auth;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<TokenResponse> refreshToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw const ApiException(message: 'Missing refresh token');
    }
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final token = ApiResponseParser.unwrap(
        response,
        (json) =>
            TokenResponse.fromJson(Map<String, dynamic>.from(json as Map)),
      );
      await _persistTokens(token);
      return token;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserModel> me() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.me);
      return ApiResponseParser.unwrap(
        response,
        (json) => UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> clearUserDataCaches() async {
    try {
      final workoutBox = await Hive.openBox<String>('personalized_workout_cache');
      await workoutBox.clear();
      final mealBox = await Hive.openBox<dynamic>('ai_meal_plan_cache');
      await mealBox.clear();
    } catch (_) {
      // Ignore cache clearing errors to prevent blocking session termination
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _dio.post<dynamic>(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } finally {
      await _tokenStorage.clear();
      await clearUserDataCaches();
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim()},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.resetPassword,
        data: {
          'resetToken': resetToken.trim(),
          'newPassword': newPassword,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<bool> hasValidLocalAccessToken() async {
    final tokens = await _tokenStorage.read();
    return tokens?.isAccessTokenValid == true;
  }

  Future<void> clearLocalSession() async {
    await _tokenStorage.clear();
    await clearUserDataCaches();
  }

  Future<void> _persistTokens(TokenResponse tokens) {
    return _tokenStorage.write(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresInMs: tokens.expiresInMs,
    );
  }
}
