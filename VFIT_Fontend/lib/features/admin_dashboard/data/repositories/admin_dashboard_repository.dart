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

  Future<PaginatedUserResponseModel> getAdminUsers({
    bool onlyVip = false,
    String? search,
    String? startDate,
    String? endDate,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (onlyVip) {
        queryParams['filter'] = 'VIP';
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (startDate != null && startDate.trim().isNotEmpty) {
        queryParams['startDate'] = startDate.trim();
      }
      if (endDate != null && endDate.trim().isNotEmpty) {
        queryParams['endDate'] = endDate.trim();
      }
      final response = await _dio.get<dynamic>(
        '/api/admin/users',
        queryParameters: queryParams,
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => PaginatedUserResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<TrafficMetricsResponseModel> getTrafficMetrics({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/admin/metrics/traffic',
        queryParameters: {'page': page, 'size': size},
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => TrafficMetricsResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<SearchMetricItemModel>> getSearchMetrics({
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/admin/metrics/searches',
        queryParameters: {'limit': limit},
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => (json as List)
            .map((item) => SearchMetricItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<RecentTransactionModel>> getMonthlyRevenueDetails(String month) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/revenue/monthly-details',
        queryParameters: {'month': month},
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => (json as List)
            .map((item) => RecentTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<RecentTransactionModel>> getUserTransactionHistory(String userId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/admin/revenue/user-transactions',
        queryParameters: {'userId': userId},
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => (json as List)
            .map((item) => RecentTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
