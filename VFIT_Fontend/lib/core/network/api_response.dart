import 'package:dio/dio.dart';

import 'api_exception.dart';

typedef JsonMapper<T> = T Function(Map<String, dynamic> json);

class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    JsonMapper<T> mapper,
  ) {
    final rawContent = json['content'] as List? ?? const [];
    return PageResponse<T>(
      content: rawContent
          .whereType<Map>()
          .map((item) => mapper(Map<String, dynamic>.from(item)))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      last: json['last'] == true,
    );
  }
}

class ApiResponseParser {
  const ApiResponseParser._();

  static T unwrap<T>(
    Response<dynamic> response,
    T Function(Object? json) mapper,
  ) {
    final body = response.data;
    if (body is! Map) {
      throw const ApiException(message: 'Invalid server response');
    }
    final json = Map<String, dynamic>.from(body);
    if (json['success'] != true) {
      throw ApiException(
        message: json['message']?.toString() ?? 'Request failed',
        code: json['code']?.toString(),
      );
    }
    return mapper(json['data']);
  }

  static PageResponse<T> unwrapPage<T>(
    Response<dynamic> response,
    JsonMapper<T> mapper,
  ) {
    return unwrap(response, (json) {
      if (json is! Map) {
        throw const ApiException(message: 'Invalid page response');
      }
      return PageResponse<T>.fromJson(Map<String, dynamic>.from(json), mapper);
    });
  }

  static void unwrapVoid(Response<dynamic> response) {
    unwrap<void>(response, (_) {});
  }
}
