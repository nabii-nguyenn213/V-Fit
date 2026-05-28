# Feature Specification: AI-Native V-FIT Baseline

**Feature Branch**: `001-ai-native-baseline`

**Created**: 2026-05-28

**Status**: Draft

**Input**: User description: "Populate AI-native Spec Kit baseline from existing
V-FIT codebase."

## User Scenarios & Testing

### User Story 1 - Complete Fitness Onboarding (Priority: P1)

A new user registers, verifies OTP, submits physical profile data, completes
onboarding, and reaches the main app with an active profile.

**Why this priority**: Identity and onboarding status are required before
protected customer flows can be trusted.

**Independent Test**: Register, verify OTP, submit onboarding metrics, upload
body scan, and confirm `/home` becomes available.

**Acceptance Scenarios**:

1. **Given** a pending user, **When** the user opens a protected route, **Then**
   the system MUST route the user to onboarding.
2. **Given** completed onboarding, **When** the user opens the app, **Then** the
   system MUST route the user to home.

---

### User Story 2 - Consume AI Premium Coaching (Priority: P1)

A premium user uses AI food scanning, AI form check, body analysis context, and
personalized workout guidance.

**Why this priority**: AI coaching is the core paid value.

**Independent Test**: Activate VIP, call an AI endpoint, and verify typed,
rate-limited, fallback-safe output.

**Acceptance Scenarios**:

1. **Given** an active VIP user, **When** the user scans food, **Then** the
   system MUST return estimated food, calories, macros, confidence, and notes.
2. **Given** an active VIP user, **When** the user streams form-check frames,
   **Then** the system MUST return real-time feedback JSON.
3. **Given** an AI provider failure, **When** an AI flow runs, **Then** the
   system MUST return a safe fallback response.

---

### User Story 3 - Train With Catalogs And Progress (Priority: P2)

A user browses workouts, exercises, muscle maps, nutrition data, daily check-in,
journey snaps, badges, and challenges.

**Why this priority**: This is the daily habit loop that keeps users active.

**Independent Test**: Browse catalog screens, create progress snapshots, join
challenges, and verify progress remains visible.

**Acceptance Scenarios**:

1. **Given** a user on workouts, **When** the user selects a workout, **Then**
   the system MUST show workout detail.
2. **Given** a user on progress, **When** the user uploads a journey snap,
   **Then** the system MUST store and list the snap.
3. **Given** challenge availability, **When** the user joins, **Then** the
   system MUST track participation.

---

### User Story 4 - Unlock Premium By Payment (Priority: P2)

A user applies vouchers, starts checkout, pays through Sepay/VietQR, and receives
VIP status.

**Why this priority**: Premium payment controls access to paid AI value.

**Independent Test**: Apply voucher, create payment, simulate webhook, and
verify subscription snapshot becomes active.

**Acceptance Scenarios**:

1. **Given** a valid voucher, **When** checkout applies it, **Then** the final
   amount MUST reflect the discount once.
2. **Given** a paid transaction, **When** the webhook is accepted, **Then** VIP
   status MUST unlock premium AI.

---

### User Story 5 - Admin Operates The Platform (Priority: P3)

An admin manages users, app configuration, exercise library seed data, and
revenue reporting.

**Why this priority**: Operators need control without entering customer flows.

**Independent Test**: Login as admin and confirm redirect to `/admin/revenue`.

**Acceptance Scenarios**:

1. **Given** an admin account, **When** login succeeds, **Then** the app MUST
   route to the admin revenue dashboard.
2. **Given** a non-admin user, **When** the user opens admin routes, **Then** the
   app MUST route back to customer home.

### Edge Cases

- AI provider returns malformed output.
- Redis is unavailable during AI rate limiting or payment locking.
- User is authenticated but onboarding is pending.
- User is free-tier and calls premium AI.
- Uploaded image is absent, too large, or unknown content type.
- Payment webhook is duplicated, expired, or unsigned.
- Voucher is expired, already used, or stacked.
- Admin attempts to access customer-only flows.

## Requirements

### Functional Requirements

- **FR-001**: System MUST authenticate users with email, password, OTP, JWT
  access tokens, refresh tokens, logout, forgot password, and reset password.
- **FR-002**: System MUST enforce onboarding before protected customer flows.
- **FR-003**: System MUST expose app configuration, workout catalog, exercise
  catalog, grouped muscle library, food search, badges, and challenges.
- **FR-004**: System MUST support profile updates, avatar upload, password
  change, body metrics, sessions, and account deletion.
- **FR-005**: System MUST support daily check-in and voucher rewards.
- **FR-006**: System MUST support progress journey snaps with photo upload,
  listing, and deletion.
- **FR-007**: System MUST support personalized workout plans based on user goal
  and seeded goal metadata.
- **FR-008**: System MUST expose AI food calorie estimation for premium users.
- **FR-009**: System MUST expose real-time AI form check over WebSocket for
  premium users.
- **FR-010**: System MUST route all AI calls through a backend AI client
  boundary.
- **FR-011**: System MUST rate-limit AI endpoints and apply circuit-breaker
  fallback behavior.
- **FR-012**: System MUST parse AI responses into bounded output contracts.
- **FR-013**: System MUST store runtime prompts under `skills/conversation/`.
- **FR-014**: System MUST store architecture decisions under
  `skills/tech-decision/decision.md`.
- **FR-015**: System MUST support premium checkout, voucher validation, payment
  creation, payment status, Sepay webhook, VietQR, and VIP status.
- **FR-016**: System MUST support admin dashboard, admin users, admin app
  config, revenue monthly data, and transactions.
- **FR-017**: System MUST return API responses through consistent success and
  error envelopes.
- **FR-018**: System MUST log operationally meaningful AI, payment, auth, and
  profile events.

### Key Entities

- **User**: Identity, role, active flag, onboarding status, physical profile,
  progress, and subscription snapshot.
- **Session And Token**: Refresh token, user session, password reset token, and
  email OTP.
- **Body Analysis Result**: AI posture, imbalance, estimate, recommendation, and
  metadata.
- **Form Check Result**: Exercise feedback, score, summary, and AI payload.
- **Food**: Searchable nutrition catalog item with calories and macros.
- **Workout Program**: Training plan and exercises for catalog browsing.
- **Goal Workout Metadata**: Goal-specific rules, schedule, nutrition, and
  recovery guidance.
- **Journey Snap**: Progress photo, note, metrics, and timestamps.
- **Challenge And Badge**: Gamification goals, rewards, participation, and
  status.
- **Voucher And Payment Transaction**: Discount, checkout, payment code, VietQR,
  payment status, expiry, and premium unlock.
- **App Config**: Public app name, slogan, support, terms, privacy, version, and
  maintenance state.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A new user can complete register, OTP verification, onboarding,
  and home access in under 5 minutes.
- **SC-002**: Premium AI calls return either a typed success response or a typed
  fallback response 100% of the time.
- **SC-003**: Free users are blocked from premium AI in 100% of tested attempts.
- **SC-004**: AI rate limiting prevents more than the configured request count
  per window for a single user or token.
- **SC-005**: Payment checkout applies at most one voucher per order in 100% of
  tested cases.
- **SC-006**: Admin users land on the revenue dashboard after login in 100% of
  tested cases.

## Assumptions

- Flutter remains the primary customer and admin client.
- Spring Boot remains the backend gateway and modular monolith.
- MongoDB remains the source of truth for application data.
- Redis remains available for cache and protection, with fallback behavior where
  implemented.
- `MockAiClient` represents the current AI boundary until a production AI Core
  client is wired.
- AI prompts are documentation-controlled now and become runtime-loaded only
  after a later implementation task.
