import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../models/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final adminDashboardProvider =
    FutureProvider.autoDispose<DashboardStatsModel>((ref) {
  return ref.watch(adminRepositoryProvider).dashboard();
});

class AdminRepository {
  const AdminRepository(this._dio);

  final Dio _dio;

  Future<DashboardStatsModel> dashboard() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.adminDashboard);
      return ApiResponseParser.unwrap(
        response,
        (json) => DashboardStatsModel.fromJson(
            Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
