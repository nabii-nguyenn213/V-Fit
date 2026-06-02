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

class SocialLoginClient {
  SocialLoginClient({
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              clientId: _googleClientId,
              serverClientId: _googleServerClientId,
            ),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  static String? get _googleClientId =>
      kIsWeb && Environment.googleWebClientId.isNotEmpty
          ? Environment.googleWebClientId
          : null;
  static String? get _googleServerClientId =>
      Environment.googleWebClientId.isNotEmpty
          ? Environment.googleWebClientId
          : null;

  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  Future<SocialLoginCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_failed' &&
          error.message?.contains('ApiException: 10') == true) {
        throw Exception(
          'Google login is not configured for this Android app. Check '
          'Google Cloud or Firebase has an Android OAuth client for package '
          '${Environment.googleAndroidPackageName} with SHA-1 '
          '${Environment.googleDebugSha1}, and that backend GOOGLE_CLIENT_ID '
          'matches Web OAuth client ${Environment.googleWebClientId}.',
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

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : defaultTargetPlatform.name;
  }
}
