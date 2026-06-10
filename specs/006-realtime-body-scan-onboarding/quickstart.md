# Quickstart: Real-time Body Scan Onboarding Flow

## Backend Setup

1. **Verify Database Connection**: Make sure MongoDB is running locally.
2. **Build and Run Backend**:
   ```bash
   cd VFIT_Backend
   ./mvnw spring-boot:run
   ```

## Frontend Setup

1. **Run Flutter Client**:
   ```bash
   cd VFIT_Fontend
   flutter pub get
   flutter run
   ```

## Verification Scenarios

1. **Simulate User Flow**:
   - Register a new account.
   - Proceed to step 1 of onboarding.
   - Click "Bắt đầu quét cơ thể realtime".
   - Place full body in view of camera.
   - As soon as AI detects posture (non-fallback and confidence > 0), the camera should stop and navigate directly to `/home`.
2. **Verify DB records**:
   - Check MongoDB user collection: `onboardingStatus` must be `"COMPLETED"` and `active` must be `true`.
   - Check `bodyAnalysisResult` collection for a document with `"source": "onboarding-realtime"`.
