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
