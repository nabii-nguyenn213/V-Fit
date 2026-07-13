import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

import '../../../../core/config/environment.dart';

class GoogleWebSignInButton extends StatefulWidget {
  const GoogleWebSignInButton({
    super.key,
    required this.loading,
    required this.onIdToken,
    required this.onError,
  });

  final bool loading;
  final Future<void> Function(String idToken) onIdToken;
  final void Function(String message) onError;

  @override
  State<GoogleWebSignInButton> createState() => _GoogleWebSignInButtonState();
}

class _GoogleWebSignInButtonState extends State<GoogleWebSignInButton> {
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _userSubscription;
  bool _handlingAccount = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'openid', 'profile'],
      clientId: Environment.googleWebClientId.isNotEmpty
          ? Environment.googleWebClientId
          : null,
    );
    _userSubscription =
        _googleSignIn.onCurrentUserChanged.listen(_handleGoogleAccount);
    unawaited(_googleSignIn.signInSilently());
  }

  @override
  void dispose() {
    unawaited(_userSubscription?.cancel());
    super.dispose();
  }

  Future<void> _handleGoogleAccount(GoogleSignInAccount? account) async {
    if (!mounted || account == null || _handlingAccount) {
      return;
    }

    setState(() {
      _handlingAccount = true;
    });

    try {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        widget.onError(
          'Google login did not return an identity token. Please try the Google button again.',
        );
        return;
      }
      await widget.onIdToken(idToken);
    } catch (error) {
      widget.onError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _handlingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading || _handlingAccount;
    return AbsorbPointer(
      absorbing: disabled,
      child: Opacity(
        opacity: disabled ? 0.62 : 1,
        child: SizedBox(
          height: 44,
          child: Center(
            child: google_web.renderButton(
              configuration: google_web.GSIButtonConfiguration(
                type: google_web.GSIButtonType.standard,
                theme: google_web.GSIButtonTheme.outline,
                size: google_web.GSIButtonSize.large,
                text: google_web.GSIButtonText.continueWith,
                shape: google_web.GSIButtonShape.pill,
                logoAlignment: google_web.GSIButtonLogoAlignment.left,
                minimumWidth: 320,
                locale: 'vi',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
