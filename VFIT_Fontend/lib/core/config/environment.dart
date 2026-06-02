import 'package:flutter/foundation.dart';

class Environment {
  const Environment._();

  static const googleAndroidPackageName = 'com.vfit.vfit_frontend';
  static const googleDebugSha1 =
      '86:79:18:F7:F0:B4:F7:01:92:12:52:29:6D:03:E0:B3:8E:88:5A:B2';
  static const googleDebugSha256 =
      '7F:6F:AB:86:A3:30:5E:5C:A4:E4:B7:0E:CD:B2:58:38:80:53:5A:0A:23:F4:21:DD:55:01:69:B0:70:C7:E8:54';
  static const defaultGoogleWebClientId =
      '82528745694-hsj5ae4dhgkfisdc184lvt79rpgv83ng.apps.googleusercontent.com';
  static const defaultGoogleAndroidClientId =
      '82528745694-cd0qsn1gl8jgb6usahfnmbgn6oshebaf.apps.googleusercontent.com';
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: defaultGoogleWebClientId,
  );

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
