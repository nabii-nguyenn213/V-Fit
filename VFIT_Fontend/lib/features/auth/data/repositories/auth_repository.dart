import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../../profile/data/models/user_model.dart';
import '../models/auth_models.dart';

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

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.register,
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

  Future<void> clearLocalSession() => _tokenStorage.clear();

  Future<void> _persistTokens(TokenResponse tokens) {
    return _tokenStorage.write(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresInMs: tokens.expiresInMs,
    );
  }
}
