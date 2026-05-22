import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details = const [],
  });

  final String message;
  final String? code;
  final int? statusCode;
  final List<String> details;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        message: data['message']?.toString() ??
            _fallbackMessage(response?.statusCode),
        code: data['code']?.toString(),
        statusCode: response?.statusCode,
        details:
            (data['details'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );
    }
    return ApiException(
      message: _networkMessage(error),
      statusCode: response?.statusCode,
    );
  }

  static String _fallbackMessage(int? statusCode) {
    return switch (statusCode) {
      400 => 'Invalid request',
      401 => 'Session expired. Please log in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'Resource not found',
      500 => 'Server error. Please try again later.',
      _ => 'Something went wrong',
    };
  }

  static String _networkMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timed out. Please try again.',
      DioExceptionType.connectionError => 'Cannot connect to the server.',
      _ => _fallbackMessage(error.response?.statusCode),
    };
  }

  @override
  String toString() => message;
}
