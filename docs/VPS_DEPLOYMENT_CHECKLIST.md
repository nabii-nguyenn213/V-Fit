# VPS Deployment Checklist

Use this checklist when moving V-FIT from local development to a VPS. Keep
secrets in VPS environment files or secret managers, not in source code.

## Target Architecture

- Spring Boot backend runs on the VPS with Docker Compose.
- Nginx or another reverse proxy terminates HTTPS and forwards to backend
  `127.0.0.1:8080`.
- Flutter production builds call the public HTTPS API domain.
- MongoDB and Redis run as managed services or private VPS services.
- Google and Facebook provider credentials are configured in provider consoles
  and backend runtime environment.

## Values To Decide Before Deploy

Fill these values before building production artifacts.

```text
API domain: https://api.<your-domain>
Web/app domain: https://<your-domain> or https://app.<your-domain>
AI API domain: https://ai.<your-domain>
Android package: com.vfit.vfit_frontend
Release keystore path: <private-keystore-path>
Release SHA-1: <release-signing-sha1>
Release SHA-256: <release-signing-sha256>
Google Web OAuth client ID: <web-oauth-client-id>
Google Android OAuth client ID: <release-android-oauth-client-id>
Facebook App ID: <facebook-app-id>
Facebook App Secret: <facebook-app-secret>
Facebook Client Token: <facebook-client-token>
Cloudinary cloud name/API key/API secret: <cloudinary-values>
MongoDB URI: <private-or-managed-mongodb-uri>
Redis host/password: <private-or-managed-redis-values>
```

## Backend Production Environment

Create `VFIT_Backend/.env.production` on the VPS from
`VFIT_Backend/.env.production.example`.

Required changes:

```env
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080
APP_BASE_URL=https://api.<your-domain>
CORS_ALLOWED_ORIGINS=https://<your-domain>,https://app.<your-domain>

MONGODB_URI=<production-mongodb-uri>
REDIS_HOST=<production-redis-host>
REDIS_PORT=6379
REDIS_PASSWORD=<production-redis-password-if-any>
REDIS_REQUIRED=true
REDIS_HEALTH_ENABLED=true

JWT_SECRET=<long-random-secret-at-least-64-bytes>
OTP_PEPPER=<different-long-random-secret>

GOOGLE_CLIENT_ID=<google-web-oauth-client-id>
FACEBOOK_APP_ID=<facebook-app-id>
FACEBOOK_APP_SECRET=<facebook-app-secret>

CLOUDINARY_CLOUD_NAME=<cloudinary-cloud-name>
CLOUDINARY_API_KEY=<cloudinary-api-key>
CLOUDINARY_API_SECRET=<cloudinary-api-secret>

SEPAY_WEBHOOK_SECRET=<production-sepay-webhook-secret>
SEPAY_BANK_CODE=<bank-code>
SEPAY_ACCOUNT_NUMBER=<account-number>
SEPAY_ACCOUNT_NAME=<account-name>

AI_CLIENT_MODE=http
AI_BASE_URL=https://ai.<your-domain>
AI_FOOD_SCANNER_PATH=/api/v1/food-scanner/
```

Bootstrap rule:

- First production deploy may use `BOOTSTRAP_ADMIN_ENABLED=true`.
- After the admin account exists, set `BOOTSTRAP_ADMIN_ENABLED=false` and
  redeploy.

Do not put these values in Flutter:

- `FACEBOOK_APP_SECRET`
- `JWT_SECRET`
- `OTP_PEPPER`
- `MONGODB_URI`
- `REDIS_PASSWORD`
- `CLOUDINARY_API_SECRET`
- payment or webhook secrets

## VPS Docker And Reverse Proxy

Backend production compose file:

```bash
cd VFIT_Backend
docker compose -f docker-compose.prod.yml up -d --build
```

The current production compose binds backend to:

```text
127.0.0.1:8080:8080
```

Keep that binding and expose the backend through Nginx HTTPS instead of opening
port `8080` publicly.

Nginx must proxy the API domain to:

```text
http://127.0.0.1:8080
```

VPS firewall should allow:

- `22/tcp` for SSH from trusted IPs.
- `80/tcp` for HTTP certificate challenge and redirect.
- `443/tcp` for HTTPS.

Do not expose MongoDB or Redis publicly.

## Flutter Production Build

Production Flutter must use the public HTTPS API URL:

### Web artifact

```powershell
cd D:\EXE_PRM\VFIT_Fontend
$env:PUB_CACHE="D:\EXE_PRM\PubCache"
flutter clean
flutter pub get
flutter build web --release `
  --dart-define=API_BASE_URL=https://api.<your-domain> `
  --dart-define=GOOGLE_WEB_CLIENT_ID=<google-web-oauth-client-id> `
  --dart-define=ENABLE_CRASHLYTICS=true
```

Deploy this generated folder to the static web host:

```text
VFIT_Fontend/build/web
```

The web host must serve HTTPS and route unknown paths back to `index.html`
because Flutter uses client-side routing.

### Android Play Store artifact

Play Store release artifacts must be Android App Bundles (`.aab`) signed with
the release upload key. Do not use the debug signing fallback for Play Store.

Create `VFIT_Fontend/android/key.properties` locally only:

```properties
storePassword=<upload-keystore-password>
keyPassword=<upload-key-password>
keyAlias=<upload-key-alias>
storeFile=<absolute-or-android-relative-path-to-upload-keystore.jks>
```

The `key.properties`, `.jks`, and `.keystore` files are ignored by git and must
stay outside source control.

For Facebook Android native configuration, set environment variables before the
build. These are read by Gradle, not by `--dart-define`.

```powershell
cd D:\EXE_PRM\VFIT_Fontend
$env:PUB_CACHE="D:\EXE_PRM\PubCache"
$env:FACEBOOK_APP_ID="<facebook-app-id>"
$env:FACEBOOK_CLIENT_TOKEN="<facebook-client-token>"
flutter clean
flutter pub get
flutter build appbundle --release `
  --build-name=1.0.0 `
  --build-number=1 `
  --dart-define=API_BASE_URL=https://api.<your-domain> `
  --dart-define=GOOGLE_WEB_CLIENT_ID=<google-web-oauth-client-id> `
  --dart-define=GOOGLE_ANDROID_SIGNING_VARIANT=release `
  --dart-define=GOOGLE_ANDROID_CLIENT_ID=<release-android-oauth-client-id> `
  --dart-define=GOOGLE_ANDROID_SHA1=<release-sha1> `
  --dart-define=GOOGLE_ANDROID_SHA256=<release-sha256>
```

Output:

```text
VFIT_Fontend/build/app/outputs/bundle/release/app-release.aab
```

For local sideload testing, APK is still useful but it is not the Play Store
upload artifact:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.<your-domain> `
  --dart-define=GOOGLE_WEB_CLIENT_ID=<google-web-oauth-client-id> `
  --dart-define=GOOGLE_ANDROID_SIGNING_VARIANT=release `
  --dart-define=GOOGLE_ANDROID_CLIENT_ID=<release-android-oauth-client-id> `
  --dart-define=GOOGLE_ANDROID_SHA1=<release-sha1> `
  --dart-define=GOOGLE_ANDROID_SHA256=<release-sha256>
```

Google Play requires new apps and updates to target Android 15/API 35 or higher
from August 31, 2025. Verify the generated Android target SDK before uploading
to Play Console.

## AI Service Production

The current production AI integration calls the FastAPI food scanner service.
Run the AI service separately from Spring Boot and point backend config to it:

```bash
cd AI-VFIT/V-Fit/RecommendationSystem
uvicorn main:app --host 0.0.0.0 --port 8000
```

Recommended deployment shape:

- Put the AI service behind HTTPS, for example `https://ai.<your-domain>`.
- Set backend `AI_CLIENT_MODE=http`.
- Set backend `AI_BASE_URL=https://ai.<your-domain>`.
- Keep Gemini/API provider keys in the AI service environment, not in Flutter.
- Do not let Flutter call the AI service directly; Flutter calls Spring Boot.

## Google OAuth Console

Google needs two client identities:

- Web OAuth client: used by Flutter as `serverClientId` and backend as
  `GOOGLE_CLIENT_ID`.
- Android OAuth client: validates package name plus signing SHA-1.

For production release:

1. Build the release APK/AAB with the release keystore.
2. Extract release certificate fingerprints:

```powershell
& E:\Android\Sdk\build-tools\37.0.0\apksigner.bat verify --print-certs `
  D:\EXE_PRM\VFIT_Fontend\build\app\outputs\flutter-apk\app-release.apk
```

3. In Google Cloud/Firebase, create or update Android OAuth client:

```text
Package name: com.vfit.vfit_frontend
SHA-1: <release-sha1>
```

4. Confirm backend `GOOGLE_CLIENT_ID` equals the Web OAuth client ID.
5. Confirm Flutter `GOOGLE_WEB_CLIENT_ID` equals the same Web OAuth client ID.

If Google login fails with `ApiException: 10`, check package name, SHA-1, and
OAuth client type before debugging backend.

## Facebook Login Console

Meta values:

- `FACEBOOK_APP_ID`: backend and Android native config.
- `FACEBOOK_APP_SECRET`: backend only.
- `FACEBOOK_CLIENT_TOKEN`: Android native config only.

Configure the Meta app:

1. Add use case/product for Facebook Login.
2. Add Android platform.
3. Set package name:

```text
com.vfit.vfit_frontend
```

4. Add debug and release key hashes.
5. Add valid OAuth redirect settings required by Meta for web/login flows.
6. If the app is in Development mode, add tester accounts before testing.
7. Before public production use, complete required app review/business
   verification if Meta requires it for requested permissions.

Backend verifies Facebook access tokens through Graph API, so backend
`FACEBOOK_APP_ID` must match the App ID that issued the frontend token.

## Cloudinary

Cloudinary values belong only in backend production environment:

```env
CLOUDINARY_CLOUD_NAME=<cloud-name>
CLOUDINARY_API_KEY=<api-key>
CLOUDINARY_API_SECRET=<api-secret>
```

Do not append folder names to `CLOUDINARY_API_KEY`. Upload folders such as
`avatars`, `snaps`, or `exercise_catalogs` are upload parameters, not API keys.

## Payment And Webhooks

For SePay or payment webhooks:

- Use production `SEPAY_WEBHOOK_SECRET`.
- Point provider webhook URL to the HTTPS API domain.
- Keep bank account fields in backend environment only.
- Verify webhook signature behavior before accepting real payments.

## Verification Tasks

- [ ] T001 Create `VFIT_Backend/.env.production` on the VPS from `VFIT_Backend/.env.production.example`.
- [ ] T002 Set production API and CORS values in `VFIT_Backend/.env.production`.
- [ ] T003 Set production MongoDB and Redis values in `VFIT_Backend/.env.production`.
- [ ] T004 Set `JWT_SECRET` and `OTP_PEPPER` in `VFIT_Backend/.env.production`.
- [ ] T005 Set Google and Facebook backend credentials in `VFIT_Backend/.env.production`.
- [ ] T006 Set Cloudinary and payment secrets in `VFIT_Backend/.env.production`.
- [ ] T007 Set `AI_CLIENT_MODE=http`, `AI_BASE_URL`, and `AI_FOOD_SCANNER_PATH`.
- [ ] T008 Start backend with `docker compose -f docker-compose.prod.yml up -d --build` from `VFIT_Backend`.
- [ ] T009 Configure Nginx HTTPS proxy from `https://api.<your-domain>` to `http://127.0.0.1:8080`.
- [ ] T010 Deploy the AI FastAPI service behind `https://ai.<your-domain>`.
- [ ] T011 Verify backend health with `curl https://api.<your-domain>/actuator/health`.
- [ ] T012 Build web artifact from `VFIT_Fontend/build/web` with production `API_BASE_URL`.
- [ ] T013 Create local Android release upload keystore and `android/key.properties`.
- [ ] T014 Build Play Store AAB from `VFIT_Fontend` with production `API_BASE_URL`.
- [ ] T015 Verify Play Store AAB targets Android 15/API 35 or higher.
- [ ] T016 Register release SHA-1 in Google Android OAuth client.
- [ ] T017 Register Android package and key hash in Meta Facebook app.
- [ ] T018 Test email/password login against production API.
- [ ] T019 Test Google login and confirm backend receives `/api/auth/social-login`.
- [ ] T020 Test Facebook login and confirm backend receives `/api/auth/social-login`.
- [ ] T021 Test nutrition food scanner and confirm backend reaches the AI service.
- [ ] T022 Disable `BOOTSTRAP_ADMIN_ENABLED` after first admin account exists.

## Deployment Is Not Complete Until

- Backend health endpoint returns healthy over HTTPS.
- Flutter app uses `https://api.<your-domain>`, not local URLs.
- Google login succeeds with release signing SHA-1.
- Facebook login succeeds with release key hash and correct Client Token.
- Email/password login still works.
- AI food scanner succeeds through Spring Boot, not direct Flutter-to-AI calls.
- Admin bootstrap is disabled after first production setup.
- Secrets are not committed to git.
