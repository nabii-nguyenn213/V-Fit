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
    final statusCode = response?.statusCode;
    if (data is Map<String, dynamic>) {
      final rawCode = data['code']?.toString();
      return ApiException(
        message: _userFriendlyMessage(
          statusCode: statusCode,
          serverCode: rawCode,
        ),
        code: rawCode,
        statusCode: statusCode,
        details:
            (data['details'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );
    }
    return ApiException(
      message: _networkMessage(error),
      statusCode: statusCode,
    );
  }

  /// Returns a user-friendly Vietnamese message based on HTTP status and
  /// backend error code. Technical internal messages are never shown directly.
  static String _userFriendlyMessage({
    required int? statusCode,
    required String? serverCode,
  }) {
    // Map backend error codes to Vietnamese user messages
    switch (serverCode) {
      case 'UNAUTHORIZED':
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 'FORBIDDEN':
        return 'Tính năng này chỉ dành cho thành viên VIP. Hãy nâng cấp để sử dụng.';
      case 'RATE_LIMITED':
        return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng chờ một lúc rồi thử lại.';
      case 'VALIDATION_ERROR':
      case 'BAD_REQUEST':
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại và thử lại.';
      case 'RESOURCE_NOT_FOUND':
        return 'Không tìm thấy dữ liệu yêu cầu.';
      case 'CONFLICT':
        return 'Thao tác bị xung đột với dữ liệu hiện có. Vui lòng thử lại.';
      case 'SERVICE_UNAVAILABLE':
        return 'Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau.';
      case 'INTERNAL_ERROR':
        return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau ít phút.';
    }
    // Fallback by HTTP status
    return switch (statusCode) {
      400 => 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại.',
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Tính năng này chỉ dành cho thành viên VIP. Hãy nâng cấp để sử dụng.',
      404 => 'Không tìm thấy dữ liệu.',
      429 => 'Quá nhiều yêu cầu. Vui lòng chờ một lúc rồi thử lại.',
      500 || 502 || 503 => 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
      _ => 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
    };
  }

  static String _networkMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Kết nối quá chậm hoặc hết thời gian. Vui lòng kiểm tra mạng và thử lại.',
      DioExceptionType.connectionError =>
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      _ => _userFriendlyMessage(
          statusCode: error.response?.statusCode,
          serverCode: null,
        ),
    };
  }

  @override
  String toString() => message;
}
