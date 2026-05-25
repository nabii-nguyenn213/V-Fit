import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../models/admin_dashboard_models.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(ref.watch(dioProvider));
});

class AdminDashboardRepository {
  final Dio _dio;

  const AdminDashboardRepository(this._dio);

  Future<MonthlyRevenueResponseModel> getMonthlyRevenueReport() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/admin/revenue/monthly');
      return ApiResponseParser.unwrap(
        response,
        (json) => MonthlyRevenueResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaginatedTransactionResponseModel> getTransactions({int page = 0, int size = 5}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/revenue/transactions',
        queryParameters: {'page': page, 'size': size},
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => PaginatedTransactionResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
