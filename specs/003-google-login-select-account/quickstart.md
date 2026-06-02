# Quickstart Guide: Google Login Force Account Selection

## Integration Overview

This feature forces the native Google Sign-in account chooser to appear on every login attempt (specifically for Android and Web clients).

### Execution steps in Dart:
1. When triggering `signInWithGoogle()`, invoke `signOut()` on the `GoogleSignIn` client instance first.
2. Catch and log any errors thrown by `signOut()` gracefully (e.g., if there was no active session to begin with).
3. Proceed with calling `signIn()` to display the native account picker.

## Verification

### Manual Verification
1. Open the application.
2. Tap "Sign in with Google" and select a Google account to log in.
3. Log out of the app.
4. Tap "Sign in with Google" again.
5. **Expected Behavior**: The Google account picker must be displayed, prompting you to choose an account. It must NOT log you in automatically using the previously chosen account.
