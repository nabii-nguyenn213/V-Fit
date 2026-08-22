import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/web_socket_url_builder.dart';
import '../models/payment_models.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

class PaymentRepository {
  const PaymentRepository(this._dio);

  final Dio _dio;

  Future<PremiumPayment> createPremiumPayment({
    required PremiumPlan plan,
    String? voucherCode,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.createPremiumPayment,
        data: CreatePremiumPaymentRequest(
          plan: plan,
          voucherCode: voucherCode,
        ).toJson(),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => PremiumPayment.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PremiumPaymentStatusResult> getPremiumPaymentStatus(
    String paymentId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.premiumPaymentStatus(paymentId),
      );
      return ApiResponseParser.unwrap(
        response,
        (json) => PremiumPaymentStatusResult.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<VipStatus> getVipStatus() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.vipStatus);
      return ApiResponseParser.unwrap(
        response,
        (json) => VipStatus.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Stream<PremiumPaymentRealtimeEvent> watchPremiumPayments() async* {
    final token = await getOrRefreshAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final channel = WebSocketChannel.connect(Uri.parse(_paymentWebSocketUrl(token)));
    try {
      await for (final message in channel.stream) {
        if (message is! String) {
          continue;
        }
        final json = jsonDecode(message);
        if (json is Map) {
          yield PremiumPaymentRealtimeEvent.fromJson(
            Map<String, dynamic>.from(json),
          );
        }
      }
    } finally {
      await channel.sink.close();
    }
  }

  String _paymentWebSocketUrl(String token) {
    return WebSocketUrlBuilder.build(
      path: '/ws/payments',
      queryParameters: {'token': token},
    );
  }

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
