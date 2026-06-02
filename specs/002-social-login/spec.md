# Feature Specification: Google And Facebook Login

**Feature Branch**: `002-social-login`

**Created**: 2026-06-02

**Status**: Draft

**Input**: User description: "Add Google and Facebook login methods."

## User Scenarios & Testing

### User Story 1 - Sign In With Google (Priority: P1)

A user taps the Google login button, completes Google consent, and enters V-FIT
with a canonical V-FIT account and V-FIT JWT tokens.

**Why this priority**: Google sign-in is the most common social login path and
reduces onboarding friction without replacing existing email/password login.

**Independent Test**: Complete Google login on Flutter, verify backend provider
token validation, persist V-FIT tokens, and route to onboarding or home based on
the returned user state.

**Acceptance Scenarios**:

1. **Given** a valid Google identity token for a new email, **When** social
   login runs, **Then** the system MUST create one V-FIT user, issue V-FIT JWTs,
   and route pending users to onboarding.
2. **Given** a valid Google identity token for an existing linked user,
   **When** social login runs, **Then** the system MUST issue fresh V-FIT JWTs
   without creating a duplicate user.
3. **Given** Google token verification fails, **When** social login runs,
   **Then** the system MUST return an explicit auth error and MUST NOT create or
   modify an account.

---

### User Story 2 - Sign In With Facebook (Priority: P1)

A user taps the Facebook login button, completes Facebook consent, and enters
V-FIT with a canonical V-FIT account and V-FIT JWT tokens.

**Why this priority**: Facebook login is required alongside Google by the user
request and must follow the same identity boundary rules.

**Independent Test**: Complete Facebook login on Flutter, verify backend
provider token validation, persist V-FIT tokens, and route to onboarding or home
based on the returned user state.

**Acceptance Scenarios**:

1. **Given** a valid Facebook access token with a verified email, **When**
   social login runs, **Then** the system MUST create or locate one V-FIT user
   and issue V-FIT JWTs.
2. **Given** Facebook does not provide a verified email, **When** social login
   runs, **Then** the system MUST return an explicit error requiring an email
   based sign-in path or provider account update.
3. **Given** the Facebook identity is already linked to another V-FIT user,
   **When** social login runs, **Then** the system MUST reject the login without
   merging accounts automatically.

---

### User Story 3 - Preserve Existing Auth And Account Safety (Priority: P2)

Existing email/password users can continue using the current auth flow, while
social login links provider identities safely to existing users by verified
email or provider subject.

**Why this priority**: Social login must not break current login, OTP,
refresh-token, onboarding, deactivated-account, or admin flows.

**Independent Test**: Run existing email/password login and social login against
users with matching email, linked provider, disabled status, and pending
onboarding status.

**Acceptance Scenarios**:

1. **Given** an existing email/password account with a verified provider email,
   **When** the user logs in with that provider, **Then** the provider identity
   MAY be linked to the existing account and V-FIT JWTs are issued.
2. **Given** a disabled V-FIT user, **When** any social login provider succeeds,
   **Then** V-FIT MUST reject the login and route the client to the disabled
   account experience.
3. **Given** existing email/password login, **When** social login is added,
   **Then** current login, refresh, logout, OTP, forgot password, and reset
   password behavior MUST remain unchanged.

### Edge Cases

- Provider token is expired, malformed, revoked, or signed for another client.
- Provider returns a valid identity but no verified email.
- Provider identity is already linked to a different V-FIT user.
- Verified email belongs to an inactive or disabled V-FIT account.
- User cancels provider consent from Flutter.
- Network fails between Flutter and provider SDK.
- Network fails between backend and provider verification service.
- The same social login request is retried after a timeout.

## Requirements

### Functional Requirements

- **FR-001**: System MUST add Google and Facebook sign-in as additional login
  methods without removing email/password login.
- **FR-002**: Flutter MUST obtain provider credentials using platform SDKs and
  send only provider type plus provider token to the V-FIT backend.
- **FR-003**: Backend MUST verify Google and Facebook tokens server-side before
  account creation, login, or linking.
- **FR-004**: Backend MUST map provider identity to one canonical V-FIT user by
  provider subject and verified email rules.
- **FR-005**: Backend MUST issue only V-FIT JWT access and refresh tokens to the
  Flutter client after provider verification succeeds.
- **FR-006**: System MUST persist provider link metadata without exposing raw
  provider tokens in user-facing responses.
- **FR-007**: System MUST audit social login success, failure, link, and
  duplicate-provider rejection events.
- **FR-008**: System MUST return API responses through the existing success and
  error envelope conventions.
- **FR-009**: System MUST route authenticated social-login users to onboarding
  or home using the same `AuthStatus` behavior as email/password login.
- **FR-010**: System MUST reject disabled users and already-linked provider
  conflicts without destructive account merges.

### Key Entities

- **Social Login Request**: Provider type, provider token, optional client
  nonce, and platform metadata.
- **Social Provider Identity**: Provider name, provider subject, verified email,
  display name, avatar URL, linked user id, and timestamps.
- **User**: Canonical V-FIT identity with email, active flag, onboarding status,
  role, and subscription state.
- **Auth Event**: Audit event for social login attempts, success, failure, link,
  and duplicate-provider rejection.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Google login succeeds for valid provider credentials and returns a
  V-FIT `AuthResponse` in 100% of tested happy-path attempts.
- **SC-002**: Facebook login succeeds for valid provider credentials with
  verified email and returns a V-FIT `AuthResponse` in 100% of tested
  happy-path attempts.
- **SC-003**: Invalid, expired, revoked, or wrong-audience provider tokens never
  create or modify V-FIT users in tested failure cases.
- **SC-004**: Existing email/password login and refresh-token flows continue to
  pass after social login is added.
- **SC-005**: Duplicate provider identity conflicts are rejected in 100% of
  tested attempts.

## Assumptions

- Flutter remains the only client for this feature.
- Google sign-in uses `google_sign_in` or a current Flutter-compatible Google
  provider SDK.
- Facebook sign-in uses `flutter_facebook_auth` or a current
  Flutter-compatible Facebook provider SDK.
- Backend provider verification uses official provider token verification
  endpoints or libraries, with configured client/app ids from environment.
- New social users remain subject to the existing onboarding guard.
