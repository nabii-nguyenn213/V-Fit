import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../models/gamification_models.dart';
import '../models/journey_snap_model.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(
    ref.watch(dioProvider),
    appTokenStorage,
  );
});

final badgesProvider =
    FutureProvider.autoDispose<PageResponse<BadgeModel>>((ref) {
  return ref.watch(progressRepositoryProvider).badges();
});

final challengesProvider =
    FutureProvider.autoDispose<PageResponse<ChallengeModel>>((ref) {
  return ref.watch(progressRepositoryProvider).challenges();
});

final journeySnapsProvider =
    FutureProvider.autoDispose<PageResponse<JourneySnapModel>>((ref) {
  return ref.watch(progressRepositoryProvider).getSnaps();
});

class ProgressRepository {
  const ProgressRepository(this._dio, [this._tokenStorage]);

  final Dio _dio;
  final TokenStorage? _tokenStorage;

  Future<PageResponse<BadgeModel>> badges() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.badges,
        queryParameters: const {
          'page': 0,
          'size': AppConstants.defaultPageSize,
        },
        options: await _authorizedOptions(),
      );
      return ApiResponseParser.unwrapPage(response, BadgeModel.fromJson);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PageResponse<ChallengeModel>> challenges() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.challenges,
        queryParameters: const {
          'page': 0,
          'size': AppConstants.defaultPageSize,
        },
        options: await _authorizedOptions(),
      );
      return ApiResponseParser.unwrapPage(response, ChallengeModel.fromJson);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PageResponse<JourneySnapModel>> getSnaps() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.progressSnaps,
        queryParameters: const {'page': 0, 'size': 50},
        options: await _authorizedOptions(),
      );
      return ApiResponseParser.unwrapPage(
        response,
        JourneySnapModel.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<JourneySnapModel> uploadSnap(XFile file, String? note) async {
    // Check daily upload limit (max 5 snaps per day)
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final existingResponse = await getSnaps();
    final todaysCount = existingResponse.content.where((snap) {
      final local = snap.createdAt.toLocal();
      return local.year == todayDate.year &&
          local.month == todayDate.month &&
          local.day == todayDate.day;
    }).length;
    if (todaysCount >= 5) {
      throw ApiException(
          message: 'Bạn đã chụp tối đa 5 ảnh trong ngày ($todaysCount/5).',
          statusCode: 400);
    }
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
        if (note != null && note.isNotEmpty) 'note': note,
      });

      final response = await _dio.post<dynamic>(
        ApiEndpoints.progressSnaps,
        data: formData,
        options: await _authorizedOptions(
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => JourneySnapModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteSnap(String id) async {
    try {
      await _dio.delete<dynamic>(
        ApiEndpoints.progressSnap(id),
        options: await _authorizedOptions(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Options> _authorizedOptions({String? contentType}) async {
    final tokenStorage = _tokenStorage ?? appTokenStorage;
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
    }

    return Options(
      contentType: contentType,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
}
