# Quickstart: Google And Facebook Login

## Backend Configuration

Add provider configuration to the backend runtime environment.

```powershell
$env:GOOGLE_CLIENT_ID="82528745694-hsj5ae4dhgkfisdc184lvt79rpgv83ng.apps.googleusercontent.com"
$env:FACEBOOK_APP_ID="facebook-app-id"
$env:FACEBOOK_APP_SECRET="facebook-app-secret"
```

Run backend tests from `VFIT_Backend`.

```powershell
mvn test
```

## Frontend Configuration

The frontend has the V-FIT Web OAuth client configured by default. Override
`GOOGLE_WEB_CLIENT_ID` only when switching Google Cloud or Firebase projects.
Use the Web OAuth client for both Flutter `GOOGLE_WEB_CLIENT_ID` and backend
`GOOGLE_CLIENT_ID`. iOS configuration is out of scope for v1.

For Android, Google Cloud or Firebase must contain an Android OAuth client with:

```text
Web OAuth client id: 82528745694-hsj5ae4dhgkfisdc184lvt79rpgv83ng.apps.googleusercontent.com
Android OAuth client id: 82528745694-cd0qsn1gl8jgb6usahfnmbgn6oshebaf.apps.googleusercontent.com
Package name: com.vfit.vfit_frontend
Debug SHA-1: 1A:87:A8:3D:41:96:5D:2E:19:A5:D1:32:7D:98:71:A8:B6:33:D3:72
Debug SHA-256: DF:93:48:4A:FA:17:C9:6C:3D:C3:88:AD:A1:E0:40:5A:04:E3:66:61:8F:9C:EC:61:D1:5A:F3:DA:60:98:BC:96
```

Android native Facebook configuration is read by Gradle from environment or
Gradle properties.

```powershell
$env:FACEBOOK_APP_ID="facebook-app-id"
$env:FACEBOOK_CLIENT_TOKEN="facebook-client-token"
```

Flutter social login uses dart defines for provider SDK client/app ids when
overrides are needed.

```powershell
flutter run --dart-define=FACEBOOK_APP_ID=facebook-app-id
```

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
