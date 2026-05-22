import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../models/challenge_model.dart';
import '../models/participation_model.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(
    ref.watch(dioProvider),
    appTokenStorage,
  );
});

final activeParticipationsProvider =
    FutureProvider.autoDispose<List<ParticipationModel>>((ref) {
  return ref.watch(challengeRepositoryProvider).getActiveParticipations();
});

class ChallengeRepository {
  const ChallengeRepository(this._dio, [this._tokenStorage]);

  final Dio _dio;
  final TokenStorage? _tokenStorage;

  Future<PageResponse<ChallengeModel>> getActiveChallenges({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/gamification/challenges',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      return ApiResponseParser.unwrapPage(response, ChallengeModel.fromJson);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ParticipationModel> joinChallenge(String challengeId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/gamification/challenges/$challengeId/join',
        options: await _authorizedOptions(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => ParticipationModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ParticipationModel> reviveStreak(String challengeId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/gamification/challenges/$challengeId/revive',
        options: await _authorizedOptions(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => ParticipationModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ParticipationModel> getParticipation(String challengeId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/gamification/challenges/$challengeId/participation',
        options: await _authorizedOptions(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => ParticipationModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ParticipationModel>> getActiveParticipations() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/gamification/challenges/active-participations',
        options: await _authorizedOptions(),
      );
      
      final list = (response.data?['data'] as List? ?? []);
      return list
          .map((item) => ParticipationModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Options> _authorizedOptions() async {
    final tokenStorage = _tokenStorage ?? appTokenStorage;
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
    }

    return Options(
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }
}
