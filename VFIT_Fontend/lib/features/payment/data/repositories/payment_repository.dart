import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
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

  Stream<PremiumPaymentRealtimeEvent> watchPremiumPayments() async* {
    final token = await appTokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final socket = await WebSocket.connect(_paymentWebSocketUrl(token));
    try {
      await for (final message in socket) {
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
      await socket.close();
    }
  }

  String _paymentWebSocketUrl(String token) {
    final baseUri = Uri.parse(Environment.apiBaseUrl);
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    return baseUri.replace(
      scheme: scheme,
      path: '/ws/payments',
      queryParameters: {'token': token},
    ).toString();
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
