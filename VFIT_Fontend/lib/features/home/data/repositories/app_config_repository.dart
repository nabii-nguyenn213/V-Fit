import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../models/app_config_model.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(ref.watch(dioProvider));
});

final appConfigProvider = FutureProvider<AppConfigModel>((ref) {
  return ref.watch(appConfigRepositoryProvider).fetch();
});

class AppConfigRepository {
  const AppConfigRepository(this._dio);

  final Dio _dio;

  Future<AppConfigModel> fetch() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.appConfig);
      return ApiResponseParser.unwrap(
        response,
        (json) =>
            AppConfigModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
