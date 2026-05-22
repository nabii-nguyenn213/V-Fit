import 'package:flutter/foundation.dart';

class Environment {
  const Environment._();

  static const _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8080',
      _ => 'http://localhost:8080',
    };
  }

  static const debugNetwork = bool.fromEnvironment(
    'DEBUG_NETWORK',
    defaultValue: false,
  );

  static const pinnedCertSha256 = String.fromEnvironment(
    'PINNED_CERT_SHA256',
    defaultValue: '',
  );

  static const enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: false,
  );
}
