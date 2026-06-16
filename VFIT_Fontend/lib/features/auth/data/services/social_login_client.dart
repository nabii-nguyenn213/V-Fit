import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/environment.dart';
import '../models/auth_models.dart';

class SocialLoginCredential {
  const SocialLoginCredential({
    required this.provider,
    required this.providerToken,
    required this.platform,
  });

  final SocialLoginProvider provider;
  final String providerToken;
  final String platform;
}

class SocialLoginConfigurationException implements Exception {
  const SocialLoginConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SocialLoginClient {
  SocialLoginClient({
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _googleSignIn = googleSignIn ??
            (kIsWeb
                ? GoogleSignIn(
                    scopes: const ['email', 'openid', 'profile'],
                    clientId: Environment.googleWebClientId.isNotEmpty
                        ? Environment.googleWebClientId
                        : null,
                  )
                : GoogleSignIn(
                    scopes: const ['email', 'profile', 'openid'],
                    serverClientId: Environment.googleWebClientId.isNotEmpty
                        ? Environment.googleWebClientId
                        : null,
                  )),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  Future<SocialLoginCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? account;
    try {
      _debugLogGoogleSignInStart();
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('[GoogleSignIn] Pre-signin signOut error: $e');
      }
      account = await _googleSignIn.signIn();
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_failed' &&
          error.message?.contains('ApiException: 10') == true) {
        _debugLogGoogleSignInFailure(error);
        throw SocialLoginConfigurationException(
          _googleAndroidConfigurationError(error),
        );
      }
      rethrow;
    }
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google login did not return an identity token.');
    }
    return SocialLoginCredential(
      provider: SocialLoginProvider.google,
      providerToken: idToken,
      platform: _platform,
    );
  }

  Future<SocialLoginCredential?> signInWithFacebook() async {
    final result = await _facebookAuth.login(
      permissions: const ['email', 'public_profile'],
    );
    if (result.status == LoginStatus.cancelled) {
      return null;
    }
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception(result.message ?? 'Facebook login failed.');
    }
    return SocialLoginCredential(
      provider: SocialLoginProvider.facebook,
      providerToken: result.accessToken!.tokenString,
      platform: _platform,
    );
  }

  String _googleAndroidConfigurationError(PlatformException error) {
    final message = StringBuffer(
      'Google login is not configured for this Android app. Check '
      'Google Cloud or Firebase has an Android OAuth client for package '
      '${Environment.googleAndroidPackageName}, ${Environment.googleAndroidSigningVariant} '
      'client id ${Environment.googleAndroidClientId}, and SHA-1 '
      '${Environment.googleAndroidSha1}. Backend GOOGLE_CLIENT_ID must match '
      'Web OAuth client ${Environment.googleWebClientId}.',
    );

    if (kDebugMode) {
      message
        ..writeln()
        ..writeln()
        ..writeln('Debug details:')
        ..writeln(
          'Google Android package: ${Environment.googleAndroidPackageName}',
        )
        ..writeln(
          'Google Android signing variant: '
          '${Environment.googleAndroidSigningVariant}',
        )
        ..writeln(
          'Google Android client id: ${Environment.googleAndroidClientId}',
        )
        ..writeln('Google Android SHA-1: ${Environment.googleAndroidSha1}')
        ..writeln('Google Android SHA-256: ${Environment.googleAndroidSha256}')
        ..writeln('Google Web client id: ${Environment.googleWebClientId}')
        ..writeln('PlatformException.code: ${error.code}')
        ..writeln('PlatformException.message: ${error.message}')
        ..write('PlatformException.details: ${error.details}');
    }

    return message.toString();
  }

  void _debugLogGoogleSignInStart() {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[GoogleSignIn] Starting provider SDK flow. Backend has not been called.',
    );
    debugPrint(
      '[GoogleSignIn] Android package=${Environment.googleAndroidPackageName}, '
      'variant=${Environment.googleAndroidSigningVariant}, '
      'androidClientId=${Environment.googleAndroidClientId}, '
      'sha1=${Environment.googleAndroidSha1}, '
      'webClientId=${Environment.googleWebClientId}',
    );
  }

  void _debugLogGoogleSignInFailure(PlatformException error) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[GoogleSignIn] Provider SDK failed before backend social-login request.',
    );
    debugPrint('[GoogleSignIn] PlatformException.code=${error.code}');
    debugPrint('[GoogleSignIn] PlatformException.message=${error.message}');
    debugPrint('[GoogleSignIn] PlatformException.details=${error.details}');
  }

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : defaultTargetPlatform.name;
  }
}
