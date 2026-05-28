# Quickstart: AI-Native V-FIT Baseline

## Backend

Run MongoDB, Redis, and backend with Docker Compose from `VFIT_Backend`.

```powershell
docker compose up --build
```

Run backend tests.

```powershell
mvn test
```

## Frontend

Run Flutter from `VFIT_Fontend`.

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Baseline Verification

1. Register and verify OTP.
2. Complete onboarding metrics and body scan.
3. Confirm protected routes unlock after onboarding.
4. Confirm free users cannot use premium AI.
5. Activate VIP through payment or seeded subscription.
6. Call food calorie estimate and verify typed output.
7. Open admin login and verify admin redirects to `/admin/revenue`.
