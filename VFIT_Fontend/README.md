# V-FIT Frontend

Flutter mobile frontend for the V-FIT Spring Boot backend.

## Backend URLs

Use the correct API base URL for your runtime:

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# iOS simulator, desktop, or web on the same machine
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Physical phone on the same Wi-Fi
flutter run --dart-define=API_BASE_URL=http://<LAN_IP_OF_BACKEND_MACHINE>:8080

# Production
flutter run --release --dart-define=API_BASE_URL=https://api.your-domain.com
```

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Google Sign-In uses the V-FIT Web OAuth client by default, so local runs do not
need `GOOGLE_WEB_CLIENT_ID` unless switching Google Cloud or Firebase projects.
Use the Web OAuth client for both Flutter `GOOGLE_WEB_CLIENT_ID` and backend
`GOOGLE_CLIENT_ID`.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=GOOGLE_WEB_CLIENT_ID=82528745694-hsj5ae4dhgkfisdc184lvt79rpgv83ng.apps.googleusercontent.com
```

For Android, Google Cloud or Firebase must also contain an Android OAuth client
with these values. Do not pass this Android client id as `GOOGLE_WEB_CLIENT_ID`.

```text
Web OAuth client id: 82528745694-hsj5ae4dhgkfisdc184lvt79rpgv83ng.apps.googleusercontent.com
Android OAuth client id: 82528745694-cd0qsn1gl8jgb6usahfnmbgn6oshebaf.apps.googleusercontent.com
Package name: com.vfit.vfit_frontend
Debug SHA-1: 1A:87:A8:3D:41:96:5D:2E:19:A5:D1:32:7D:98:71:A8:B6:33:D3:72
Debug SHA-256: DF:93:48:4A:FA:17:C9:6C:3D:C3:88:AD:A1:E0:40:5A:04:E3:66:61:8F:9C:EC:61:D1:5A:F3:DA:60:98:BC:96
```

The backend must use the same Web OAuth client id as `GOOGLE_CLIENT_ID`.

If this folder was created without platform folders because Flutter CLI was unavailable, run this once inside this directory:

```bash
flutter create . --project-name vfit_frontend --org com.vfit --platforms=android,ios,web
```

## Local Admin Login

```text
email: admin@vfit.com
password: Admin@123
```

Do not hardcode production credentials in the app.
