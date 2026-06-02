# Quickstart: Google And Facebook Login

## Backend Configuration

Add provider configuration to the backend runtime environment.

```powershell
$env:GOOGLE_CLIENT_ID="google-client-id"
$env:FACEBOOK_APP_ID="facebook-app-id"
$env:FACEBOOK_APP_SECRET="facebook-app-secret"
```

Run backend tests from `VFIT_Backend`.

```powershell
mvn test
```

## Frontend Configuration

Add provider SDK configuration for Android, iOS, and web according to the
selected Flutter packages.

Run Flutter dependency install and analysis from `VFIT_Fontend`.

```powershell
flutter pub get
flutter analyze
```

## Verification

1. Open `/login`.
2. Tap Google login and complete consent.
3. Confirm V-FIT tokens are stored and user routes to onboarding or home.
4. Log out.
5. Tap Facebook login and complete consent.
6. Confirm V-FIT tokens are stored and user routes to onboarding or home.
7. Try an invalid provider token against `POST /api/auth/social-login`.
8. Confirm backend returns an explicit auth error and no user is created.
9. Confirm email/password login still works.
