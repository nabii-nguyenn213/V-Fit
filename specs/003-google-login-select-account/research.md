# Research: Google Sign-In Force Account Selection

## Decision

To force the Google account selection prompt on every login attempt (specifically when the user has multiple accounts or has previously logged in), we will call `signOut()` on the `GoogleSignIn` instance immediately before initiating the `signIn()` flow. 

In `VFIT_Fontend/lib/features/auth/data/services/social_login_client.dart`:
```dart
  Future<SocialLoginCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? account;
    try {
      _debugLogGoogleSignInStart();
      
      // Force account selection by signing out of the local session first
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('[GoogleSignIn] Pre-signin signOut error: $e');
      }
      
      account = await _googleSignIn.signIn();
    } ...
```

## Rationale

- **Simplicity**: The Flutter `google_sign_in` package (v6.2.2) does not support a direct `prompt: 'select_account'` parameter through its native Android/iOS wrapper configurations. Calling `signOut()` resets the native Google SDK sign-in state, which forces the Google account picker sheet to appear on the next `signIn()` call.
- **Minimal User Impact**: Calling `signOut()` only clears the local credential state and forces the account chooser. Unlike `disconnect()`, it does not revoke the application's OAuth permissions/scopes entirely, saving users from having to re-approve the scopes (consent screen) every time they log in.
- **Safety**: Wrapped in a try-catch block, so if the Google client is already in a signed-out state or throws an error, the flow falls back to standard `signIn()` without crashing.

## Alternatives Considered

1. **Calling `_googleSignIn.disconnect()`**:
   - *Pros*: Completely resets all session metadata.
   - *Cons*: Revokes app permissions, forcing the user to grant permission (scopes) every time they log in. This is a poor user experience.
2. **Passing `prompt: 'select_account'` (Web-only)**:
   - *Pros*: Native support for OAuth prompt configurations.
   - *Cons*: Not supported out-of-the-box by the Flutter `google_sign_in` mobile package on Android. Since the v1 scope is Android and Web, a unified approach like pre-signin `signOut()` is more portable and robust.
