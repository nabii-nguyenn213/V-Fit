import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/environment.dart';
import '../constants/api_endpoints.dart';
import 'api_response.dart';
import 'auth_logout_signal.dart';
import 'token_storage.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final appTokenStorage = SecureTokenStorage(const FlutterSecureStorage());

final dioProvider = Provider<Dio>((ref) {
  final connectTimeout = _localApiFallbackEnabled
      ? const Duration(seconds: 5)
      : const Duration(seconds: 15);
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  _configureLocalApiFallback(dio);
  dio.interceptors.add(
    AuthInterceptor(
      appTokenStorage,
      onLogout: () {
        ref.read(authLogoutSignalProvider).triggerLogout();
      },
    ),
  );
  _configureSslPinning(dio);
  if (kDebugMode && Environment.debugNetwork) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  return dio;
});

void _configureSslPinning(Dio dio) {
  final pinnedSha256 = Environment.pinnedCertSha256.trim().toLowerCase();
  if (pinnedSha256.isEmpty || kIsWeb) {
    return;
  }
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (certificate, host, port) {
        final actual = sha256.convert(certificate.der).toString().toLowerCase();
        return actual == pinnedSha256;
      };
      return client;
    },
  );
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, {required this.onLogout})
      : _refreshDio = Dio(
          BaseOptions(
            baseUrl: Environment.apiBaseUrl,
            connectTimeout: _localApiFallbackEnabled
                ? const Duration(seconds: 5)
                : const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _configureLocalApiFallback(_refreshDio);
  }

  final TokenStorage _tokenStorage;
  final VoidCallback onLogout;
  final Dio _refreshDio;
  Future<void>? _refreshFuture;

  static const _publicPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.verifyOtp,
    ApiEndpoints.refreshToken,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
    ApiEndpoints.appConfig,
    ApiEndpoints.groupedExercises,
    ApiEndpoints.exercises,
    ApiEndpoints.workouts,
    ApiEndpoints.foodSearch,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicRequest(options)) {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final alreadyRetried = request.extra['vfitRetried'] == true;
    final shouldRefresh = err.response?.statusCode == 401 &&
        request.path != ApiEndpoints.refreshToken &&
        !_isPublicRequest(request) &&
        !alreadyRetried;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    try {
      _refreshFuture ??= _refreshTokens();
      await _refreshFuture;
      _refreshFuture = null;

      final accessToken = await _tokenStorage.readAccessToken();
      request.extra['vfitRetried'] = true;
      request.headers['Authorization'] = 'Bearer $accessToken';
      final response = await _refreshDio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      _refreshFuture = null;
      await _tokenStorage.clear();
      onLogout();
      handler.next(err);
    }
  }

  Future<void> _refreshTokens() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw StateError('Missing refresh token');
    }
    final response = await _refreshDio.post<dynamic>(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    final token = ApiResponseParser.unwrap(response, (json) {
      final data = Map<String, dynamic>.from(json as Map);
      return (
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        expiresInMs: (data['expiresInMs'] as num).toInt(),
      );
    });
    await _tokenStorage.write(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresInMs: token.expiresInMs,
    );
  }

  bool _isPublicRequest(RequestOptions options) {
    final isPublicGet = options.method.toUpperCase() == 'GET' &&
        (_publicPaths.contains(options.path) ||
            options.path.startsWith('${ApiEndpoints.exercises}/') ||
            options.path.startsWith('${ApiEndpoints.workouts}/'));
    return _publicPaths.contains(options.path) || isPublicGet;
  }
}

void _configureLocalApiFallback(Dio dio) {
  final candidates = Environment.apiBaseUrlCandidates;
  if (!_localApiFallbackEnabled) {
    return;
  }
  dio.interceptors.add(LocalApiFallbackInterceptor(dio, candidates));
}

bool get _localApiFallbackEnabled {
  return kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      Environment.apiBaseUrlCandidates.length > 1;
}

class LocalApiFallbackInterceptor extends Interceptor {
  LocalApiFallbackInterceptor(this._dio, this._baseUrls);

  final Dio _dio;
  final List<String> _baseUrls;

  static const _retryIndexKey = 'vfitLocalApiFallbackIndex';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isConnectionFailure(err)) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;
    final currentIndex = request.extra[_retryIndexKey] as int? ??
        _baseUrls.indexOf(request.baseUrl);
    final nextIndex = currentIndex + 1;
    if (nextIndex >= _baseUrls.length) {
      handler.next(err);
      return;
    }

    try {
      request.baseUrl = _baseUrls[nextIndex];
      request.extra[_retryIndexKey] = nextIndex;
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isConnectionFailure(DioException err) {
    return err.response == null &&
        (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout);
  }
}
