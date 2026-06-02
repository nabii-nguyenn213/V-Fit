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
Debug SHA-1: 86:79:18:F7:F0:B4:F7:01:92:12:52:29:6D:03:E0:B3:8E:88:5A:B2
Debug SHA-256: 7F:6F:AB:86:A3:30:5E:5C:A4:E4:B7:0E:CD:B2:58:38:80:53:5A:0A:23:F4:21:DD:55:01:69:B0:70:C7:E8:54
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
