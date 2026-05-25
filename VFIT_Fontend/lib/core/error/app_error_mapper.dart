import 'package:dio/dio.dart';

import '../network/api_exception.dart';

class AppErrorMapper {
  const AppErrorMapper._();

  static String friendlyMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      return switch (status) {
        400 => 'Dữ liệu gửi lên chưa hợp lệ.',
        401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        403 => 'Bạn chưa có quyền sử dụng tính năng này.',
        429 => 'Bạn thao tác quá nhanh. Vui lòng thử lại sau.',
        500 => 'Hệ thống đang bận. Vui lòng thử lại sau.',
        _ => 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.',
      };
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
