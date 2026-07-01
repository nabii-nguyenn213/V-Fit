# Data Model: Registration 7-Day VIP Trial and Profile Redesign

## User Subscription Snapshot (Embedded in User Document)
- **Entity**: `User.SubscriptionSnapshot`
- **Fields**:
  - `status`: `SubscriptionStatus` (`FREE` or `ACTIVE` during trial)
  - `planCode`: `String` (set to `"VIP_TRIAL"` for trial)
  - `premiumUntil`: `Instant` (expires 7 days from user creation/activation)

## ErrorCode Enum
- **Entity**: `ErrorCode` (Backend)
- **New Value**:
  - `ONBOARDING_REQUIRED(HttpStatus.FORBIDDEN, "ONBOARDING_REQUIRED", "Onboarding must be completed before using this feature")`

## Update Profile Request
- **Entity**: `UpdateProfileRequest` (Backend)
- **Validation**:
  - `fullName`: Required, Sanitized (no HTML tags)
  - `heightCm`: Optional, 80 to 250 cm
  - `weightKg`: Optional, 20 to 300 kg
  - `bodyFatPercent`: Optional, 1 to 70%
