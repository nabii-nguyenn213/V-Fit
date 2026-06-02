# Implementation Plan: Google And Facebook Login

**Branch**: `002-social-login` | **Date**: 2026-06-02 |
**Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-social-login/spec.md`

## Summary

Add Google and Facebook as first-class login methods while preserving the
existing email/password, OTP, refresh-token, logout, forgot-password, reset
password, onboarding, disabled-account, and admin routing flows. Flutter will
obtain provider credentials through provider SDKs, send provider type and token
to Spring Boot, and Spring Boot will verify the provider token server-side,
resolve or create one canonical V-FIT user, issue V-FIT JWTs, and return the
existing `AuthResponse` envelope.

## Technical Context

**Language/Version**: Java 21, Dart SDK >=3.4.0 <4.0.0, Flutter 3.x.

**Primary Dependencies**: Spring Boot 3.3.5, Spring Security, MongoDB, Redis,
JJWT, OpenAPI, MapStruct, Lombok, Flutter Riverpod, BLoC, GoRouter, Dio,
Flutter Secure Storage, Google provider SDK, Facebook provider SDK.

**Storage**: MongoDB users plus provider identity metadata; existing secure
client token storage for V-FIT JWTs; no raw provider tokens persisted.

**Testing**: Maven tests for backend auth service/controller/provider verifier;
Flutter widget/unit tests for login UI, repository, controller, and routing.

**Target Platform**: Mobile-first Flutter app for Android, iOS, and web where
provider SDK support is available; Spring Boot API deployed by Docker Compose
behind Nginx.

**Project Type**: Mobile app plus API modular monolith.

**Performance Goals**: Social login SHOULD complete within standard mobile auth
expectations after provider consent; backend provider verification SHOULD avoid
blocking unrelated auth flows during provider outage.

**Constraints**: Provider credentials MUST be verified server-side; backend MUST
issue only V-FIT JWTs; provider token failure MUST NOT create, link, disable, or
merge accounts; existing auth endpoints MUST remain compatible.

**Scale/Scope**: Covers login with Google and Facebook, canonical account
linking, provider conflict handling, auth audit events, Flutter login UI, and
API contract updates.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- AI-Native Control Plane: PASS. Feature does not add AI behavior.
- Prompt Governance: PASS. No runtime prompt changes are required.
- Data Boundary Discipline: PASS. Auth provider inputs are minimized to
  provider type and token; backend validates before state changes.
- Observable Modular Monolith: PASS. Work remains inside auth, user, security,
  core network, and Flutter auth feature modules.
- Premium Safety Gates: PASS. Existing premium gates continue to rely on V-FIT
  JWT identity and subscription state.
- Authentication Identity Integrity: PASS. Plan requires server-side provider
  verification, canonical user mapping, V-FIT JWT issuance, audit events, and
  explicit non-destructive errors.

## Project Structure

### Documentation

```text
specs/
`-- 002-social-login/
    |-- spec.md
    |-- plan.md
    |-- research.md
    |-- data-model.md
    |-- quickstart.md
    `-- contracts/
        `-- auth-social-login.md
```

### Source Code

```text
VFIT_Backend/
|-- src/main/java/com/vfit/
|   |-- common/
|   |-- security/
|   `-- modules/
|       |-- auth/
|       |   |-- controller/
|       |   |-- document/
|       |   |-- dto/
|       |   |-- repository/
|       |   `-- service/
|       `-- user/
`-- src/test/java/com/vfit/

VFIT_Fontend/
|-- lib/
|   |-- core/constants/api_endpoints.dart
|   |-- core/network/
|   `-- features/auth/
|       |-- application/
|       |-- data/
|       `-- presentation/
`-- test/
```

**Structure Decision**: Keep social login inside the existing auth feature. Add
provider verification as backend auth services and provider identity persistence
as auth/user data, while reusing `AuthResponse`, token storage, and auth routing
on the client.

## Social Login Architecture

```text
Flutter LoginPage
-> Provider SDK consent
-> Provider token returned to Flutter
-> POST /api/auth/social-login
-> AuthController
-> AuthService.socialLogin
-> SocialProviderVerifier
-> SocialIdentityRepository or User provider identity field
-> UserRepository canonical user lookup/create/link
-> issueTokens(user)
-> AuthResponse
-> AuthRepository persists V-FIT JWTs
-> AuthController.setUser
-> GoRouter onboarding/home/admin/deactivated routing
```

## Phase 0: Research

1. Confirm Flutter packages for Google and Facebook provider login across
   Android, iOS, and web.
2. Confirm backend verification strategy for Google ID tokens and Facebook
   access tokens.
3. Decide provider identity persistence shape: embedded user provider links vs
   separate auth collection.
4. Decide duplicate-account and verified-email linking behavior.
5. Decide audit event storage/logging level for auth provider events.

## Phase 1: Design

1. Add backend request DTO:
   `VFIT_Backend/src/main/java/com/vfit/modules/auth/dto/request/SocialLoginRequest.java`.
2. Add provider enum and normalized identity DTO under:
   `VFIT_Backend/src/main/java/com/vfit/modules/auth/dto/`.
3. Add provider verification service interface and Google/Facebook
   implementations under:
   `VFIT_Backend/src/main/java/com/vfit/modules/auth/service/`.
4. Add `socialLogin(SocialLoginRequest request)` to `AuthService` and
   `AuthServiceImpl`.
5. Add `POST /api/auth/social-login` and `/api/v1/auth/social-login` support in
   `AuthController`.
6. Persist provider identity links without raw provider tokens in MongoDB.
7. Extend Flutter `ApiEndpoints`, `AuthRepository`, `AuthController`, auth
   models, auth events/states, and `LoginPage` for social login.
8. Add provider SDK configuration for Android, iOS, and web as required by the
   selected packages.
9. Add backend and Flutter tests for success, disabled user, invalid token,
   missing email, duplicate provider, and existing email/password compatibility.

## Constitution Re-Check

- Authentication Identity Integrity remains PASS because provider verification
  and canonical account linking are explicit backend responsibilities.
- Observable Modular Monolith remains PASS because no new service boundary is
  introduced.
- Data Boundary Discipline remains PASS because raw provider tokens are not
  persisted or returned.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | Not applicable | Not applicable |
