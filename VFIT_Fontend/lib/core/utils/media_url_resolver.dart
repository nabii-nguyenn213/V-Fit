import '../config/environment.dart';

class MediaUrlResolver {
  const MediaUrlResolver._();

  static String? resolveNullable(String? mediaPathOrUrl) {
    if (mediaPathOrUrl == null || mediaPathOrUrl.isEmpty) {
      return null;
    }
    return resolve(mediaPathOrUrl);
  }

  static String resolve(String mediaPathOrUrl) {
    final apiBaseUrl = Environment.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(mediaPathOrUrl);

    if (uri != null && uri.hasScheme) {
      if (_shouldUseConfiguredHost(uri)) {
        final baseUri = Uri.parse(apiBaseUrl);
        return uri
            .replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.hasPort ? baseUri.port : null,
            )
            .toString();
      }
      return mediaPathOrUrl;
    }

    final cleanPath = mediaPathOrUrl.replaceFirst(RegExp(r'^/+'), '');
    final uploadPath =
        cleanPath.startsWith('uploads/') ? cleanPath : 'uploads/$cleanPath';
    return '$apiBaseUrl/$uploadPath';
  }

  static bool _shouldUseConfiguredHost(Uri uri) {
    return uri.host == 'localhost' || uri.host == '127.0.0.1';
  }
}
