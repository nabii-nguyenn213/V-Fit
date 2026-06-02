# V-FIT Deploy-Ready Architecture Rules

These rules are the source of truth for code that must survive local debug,
staging, and production deployment. Follow them before changing auth, config,
networking, mobile signing, backend deployment, or any cross-boundary contract.

## Core Rule

Deployable code must separate:

- Public build-time client configuration in Flutter.
- Private runtime server configuration in Spring Boot.
- Provider credentials and signing fingerprints in Google/Facebook consoles.
- Secrets outside source control.

Do not fix deploy problems by scattering ids, URLs, SHA fingerprints, or secrets
through feature code.

## Frontend Configuration Boundary

Flutter public config belongs in:

```text
VFIT_Fontend/lib/core/config/environment.dart
```

Use `String.fromEnvironment` or `bool.fromEnvironment` for build-time values.
Feature code must read configuration through `Environment`, not from ad hoc
constants.

Allowed public Flutter dart-defines:

```text
API_BASE_URL
DEBUG_NETWORK
PINNED_CERT_SHA256
ENABLE_CRASHLYTICS
GOOGLE_WEB_CLIENT_ID
GOOGLE_ANDROID_CLIENT_ID
GOOGLE_ANDROID_PACKAGE_NAME
GOOGLE_ANDROID_SIGNING_VARIANT
GOOGLE_ANDROID_SHA1
GOOGLE_ANDROID_SHA256
```

Rules:

- `GOOGLE_WEB_CLIENT_ID` is the Web OAuth client id.
- `GOOGLE_ANDROID_CLIENT_ID` is diagnostic metadata for the Android OAuth
  client and must not be passed as `GOOGLE_WEB_CLIENT_ID`.
- Android debug/profile signing must match the debug SHA registered in Google
  Cloud/Firebase.
- Release builds must override Android diagnostic values with release signing
  metadata.
- Do not put API secrets, MongoDB URLs, JWT secrets, app secrets, or private
  keystore passwords in Flutter code.

## Backend Configuration Boundary

Spring Boot private runtime config belongs in environment files or deployment
secrets:

```text
VFIT_Backend/.env.example
VFIT_Backend/.env.production.example
VFIT_Backend/src/main/resources/application*.properties
```

Backend code reads config through Spring properties. Do not hardcode provider
secrets, JWT secrets, database URIs, payment secrets, or production URLs in Java
classes.

Required social login backend values:

```text
GOOGLE_CLIENT_ID=<web-oauth-client-id>
FACEBOOK_APP_ID=<facebook-app-id>
FACEBOOK_APP_SECRET=<facebook-app-secret>
```

Rules:

- `GOOGLE_CLIENT_ID` must match the Google Web OAuth client id used by Flutter.
- Backend verifies provider tokens server-side before creating or linking users.
- Raw provider tokens must not be persisted.
- Backend owns V-FIT JWT issuance; Flutter never trusts provider identity alone.

## Google OAuth Architecture

Google login has two separate client identities:

```text
Web OAuth client:
  Used by Flutter as serverClientId and by backend as GOOGLE_CLIENT_ID.

Android OAuth client:
  Used by Google Play Services to validate package name plus signing SHA-1.
```

Current local debug values:

```text
Web OAuth client id:
82528745694-hsj5ae4dhgkfisdc184lvt79rpgv83ng.apps.googleusercontent.com

Android OAuth client id:
82528745694-cd0qsn1gl8jgb6usahfnmbgn6oshebaf.apps.googleusercontent.com

Package:
com.vfit.vfit_frontend

Debug SHA-1:
1A:87:A8:3D:41:96:5D:2E:19:A5:D1:32:7D:98:71:A8:B6:33:D3:72
```

If Google Sign-In reports `ApiException: 10`, debug in this order:

1. Confirm Flutter logs say backend has not been called.
2. Confirm the Android OAuth client is type Android, not Web.
3. Confirm package name exactly matches `com.vfit.vfit_frontend`.
4. Confirm SHA-1 matches the built APK certificate.
5. Confirm the Web OAuth client id is used as `serverClientId` and backend
   `GOOGLE_CLIENT_ID`.

The backend is only involved after Flutter logs:

```text
[AuthRepository] POST /api/auth/social-login
```

## Android Signing Rules

Debug and profile builds are configured in:

```text
VFIT_Fontend/android/app/build.gradle.kts
```

Debug/profile builds must sign with:

```text
%USERPROFILE%\.android\debug.keystore
```

Override only when intentionally using a different debug key:

```text
ANDROID_DEBUG_KEYSTORE=<absolute-path-to-debug-keystore>
```

Release builds use `android/key.properties` when present. Release keystores are
private deployment secrets and must not be committed.

Before adding or changing a Google Android OAuth client, verify the built APK:

```powershell
& E:\Android\Sdk\build-tools\37.0.0\apksigner.bat verify --print-certs `
  D:\EXE_PRM\VFIT_Fontend\build\app\outputs\flutter-apk\app-debug.apk
```

For release:

```powershell
& E:\Android\Sdk\build-tools\37.0.0\apksigner.bat verify --print-certs `
  <path-to-release-apk>
```

Register one Android OAuth client per package plus signing SHA-1.

## Network And API Boundary

Flutter must call backend through `Environment.apiBaseUrl` and existing Dio
providers. Endpoints belong in:

```text
VFIT_Fontend/lib/core/constants/api_endpoints.dart
```

Rules:

- Android emulator local API uses `http://10.0.2.2:8080`.
- Same-machine web/desktop local API uses `http://localhost:8080`.
- Production mobile app must use an HTTPS API domain.
- Flutter must not call MongoDB, Redis, AI providers, payment providers, or
  auth providers directly except approved provider SDK login flows.
- Backend must expose behavior through typed controllers, services, DTOs, and
  `ApiResponse`.

## Code Architecture Rules

Frontend:

- Shared config, network, routing, theme, and generic widgets stay in
  `VFIT_Fontend/lib/core/`.
- Feature logic stays under `VFIT_Fontend/lib/features/<feature>/`.
- Widgets render state; repositories and controllers own side effects.
- Auth provider SDK work belongs in `features/auth/data/services/`.
- Backend API calls belong in feature repositories through Dio.

Backend:

- Keep the modular monolith boundary under `VFIT_Backend/src/main/java/com/vfit/modules/`.
- Controllers accept request DTOs and return response DTOs or `ApiResponse`.
- Services own business decisions and provider verification.
- Repositories own persistence access.
- Security filters and JWT behavior stay under `security/`.
- Cross-cutting external clients stay under `infrastructure/external/`.

Cross-boundary:

- Every public request/response contract must be documented in `specs/` or
  OpenSpec artifacts when behavior changes.
- Mobile and backend must agree on enum names, endpoint paths, and error codes.
- Add explicit logs for boundary failures without leaking secrets or raw tokens.

## Deployment Gates

Run the smallest useful gate during iteration and the broader gate before
handoff.

Frontend config or auth service changes:

```powershell
cd D:\EXE_PRM\VFIT_Fontend
& E:\Android\flutter_windows_3.41.9-stable\flutter\bin\cache\dart-sdk\bin\dart.exe analyze `
  lib\core\config\environment.dart `
  lib\features\auth\data\services\social_login_client.dart `
  lib\features\auth\data\repositories\auth_repository.dart
```

Android signing or Gradle changes:

```powershell
cd D:\EXE_PRM\VFIT_Fontend
$env:PUB_CACHE="D:\EXE_PRM\PubCache"
& E:\Android\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat build apk --debug
& E:\Android\Sdk\build-tools\37.0.0\apksigner.bat verify --print-certs `
  D:\EXE_PRM\VFIT_Fontend\build\app\outputs\flutter-apk\app-debug.apk
```

Backend auth/provider changes:

```powershell
cd D:\EXE_PRM\VFIT_Backend
mvn test
```

Production backend deploy:

```bash
cd VFIT_Backend
docker compose -f docker-compose.prod.yml up -d --build
curl http://127.0.0.1:8080/actuator/health
```

## Release Build Pattern

For Android release, do not rely on debug defaults. Pass release diagnostics:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.your-domain.com `
  --dart-define=GOOGLE_ANDROID_SIGNING_VARIANT=release `
  --dart-define=GOOGLE_ANDROID_CLIENT_ID=<release-android-oauth-client-id> `
  --dart-define=GOOGLE_ANDROID_SHA1=<release-sha-1> `
  --dart-define=GOOGLE_ANDROID_SHA256=<release-sha-256>
```

The backend production environment must include:

```text
APP_BASE_URL=https://api.your-domain.com
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://app.your-domain.com
GOOGLE_CLIENT_ID=<web-oauth-client-id>
JWT_SECRET=<long-random-secret>
OTP_PEPPER=<different-long-random-secret>
MONGODB_URI=<private-mongodb-uri>
```

## Handoff Rules

Before saying deploy work is complete:

- Commit and push code plus Beads state.
- State exact verification commands and results.
- State which environment each client id/SHA belongs to.
- State whether backend was called or provider SDK failed before backend.
- Do not leave local-only config changes undocumented.
