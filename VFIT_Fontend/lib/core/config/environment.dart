import 'package:flutter/foundation.dart';

class Environment {
  const Environment._();

  static const defaultGoogleWebClientId =
      '82528745694-hsj5ae4dhgkfisdc184lvt79rpgv83ng.apps.googleusercontent.com';
  static const defaultGoogleAndroidClientId =
      '82528745694-cd0qsn1gl8jgb6usahfnmbgn6oshebaf.apps.googleusercontent.com';
  static const defaultGoogleAndroidPackageName = 'com.vfit.vfit_frontend';
  static const defaultGoogleAndroidSha1 =
      '1A:87:A8:3D:41:96:5D:2E:19:A5:D1:32:7D:98:71:A8:B6:33:D3:72';
  static const defaultGoogleAndroidSha256 =
      'DF:93:48:4A:FA:17:C9:6C:3D:C3:88:AD:A1:E0:40:5A:04:E3:66:61:8F:9C:EC:61:D1:5A:F3:DA:60:98:BC:96';
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: defaultGoogleWebClientId,
  );
  static const googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: defaultGoogleAndroidClientId,
  );
  static const googleAndroidPackageName = String.fromEnvironment(
    'GOOGLE_ANDROID_PACKAGE_NAME',
    defaultValue: defaultGoogleAndroidPackageName,
  );
  static const googleAndroidSigningVariant = String.fromEnvironment(
    'GOOGLE_ANDROID_SIGNING_VARIANT',
    defaultValue: 'debug',
  );
  static const googleAndroidSha1 = String.fromEnvironment(
    'GOOGLE_ANDROID_SHA1',
    defaultValue: defaultGoogleAndroidSha1,
  );
  static const googleAndroidSha256 = String.fromEnvironment(
    'GOOGLE_ANDROID_SHA256',
    defaultValue: defaultGoogleAndroidSha256,
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
      TargetPlatform.android => 'http://192.168.1.93:8080',
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
