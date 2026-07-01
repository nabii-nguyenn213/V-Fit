# Quickstart: Registration 7-Day VIP Trial and Profile Redesign

## Backend Verification
1. Start the spring-boot backend.
2. Run test registration via API client or mobile app:
   - Call `/api/auth/register` to trigger OTP.
   - Call `/api/auth/verify-otp` with the OTP.
3. Check the returned `UserResponse`:
   - `subscriptionStatus` should be `ACTIVE`.
   - `subscriptionPlanCode` should be `"VIP_TRIAL"`.
   - `premiumActive` should be `true`.
   - `premiumPlan` should be `"Vip Trial"`.
   - `premiumRemainingDays` should be `7` (or `6` depending on rounding).

## Frontend Verification
1. Run Flutter application.
2. Complete registration/OTP and go to Profile.
3. Observe:
   - The VIP badge shows `"Vip Trial"`.
   - Edit Profile page is fully in accented Vietnamese.
   - If onboarding is skipped/pending, body metrics display shows the onboarding requirement prompt.
