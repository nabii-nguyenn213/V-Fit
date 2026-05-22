import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../models/payment_models.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

class PaymentRepository {
  const PaymentRepository(this._dio);

  final Dio _dio;

  Future<PaymentQuote> applyVoucher(String voucherCode) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.applyVoucher,
        data: CheckoutRequest(voucherCode: voucherCode).toJson(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => PaymentQuote.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CheckoutResult> checkout({String? voucherCode}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.checkout,
        data: CheckoutRequest(voucherCode: voucherCode).toJson(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) =>
            CheckoutResult.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
