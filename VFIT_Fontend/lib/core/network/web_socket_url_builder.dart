import '../config/environment.dart';

class WebSocketUrlBuilder {
  const WebSocketUrlBuilder._();

  static String build({
    required String path,
    required Map<String, String> queryParameters,
  }) {
    final baseUri = Uri.parse(Environment.apiBaseUrl);
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    return baseUri
        .replace(
          scheme: scheme,
          path: path,
          queryParameters: queryParameters,
        )
        .toString();
  }
}
