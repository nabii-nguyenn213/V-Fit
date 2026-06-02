# Implementation Plan: Google Login Force Account Selection

**Branch**: `003-google-login-select-account` | **Date**: 2026-06-02 | **Spec**: [specs/003-google-login-select-account/spec.md](spec.md)

**Input**: Feature specification from `/specs/003-google-login-select-account/spec.md`

## Summary

This feature ensures that clicking the "Sign in with Google" button always triggers the Google account chooser, allowing users with multiple accounts to select their desired identity. We achieve this on the client side (Flutter) by invoking `signOut()` on the `GoogleSignIn` instance immediately prior to starting the sign-in flow.

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x

**Primary Dependencies**: google_sign_in: ^6.2.2

**Storage**: N/A

**Testing**: flutter_test

**Target Platform**: Android and Web

**Project Type**: mobile-app / frontend

**Performance Goals**: Google Sign-In dialog display < 1 second.

**Constraints**: Local client changes only.

**Scale/Scope**: Modified `SocialLoginClient` within the auth feature.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Validate the active plan against the V-FIT constitution:

- AI-native control plane is explicit for reasoning-driven behavior: **Pass (Not applicable)**
- Prompt files under `skills/conversation/` own AI behavior: **Pass (Not applicable)**
- AI input and output contracts are bounded and reviewable: **Pass (Not applicable)**
- Backend module boundaries, observability, and error envelopes remain intact: **Pass (No backend changes)**
- Premium AI paths enforce onboarding, JWT, subscription gates, rate limits, and fallback behavior: **Pass (Not applicable)**
- Authentication changes preserve canonical V-FIT user identity, verify Google and Facebook provider tokens server-side, issue V-FIT JWTs only, and audit login/link/unlink events: **Pass (Social login client configuration matches specs and constitution)**

## Project Structure

### Documentation (this feature)

```text
specs/003-google-login-select-account/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── quickstart.md        # Phase 1 output
```

### Source Code (repository root)

```text
VFIT_Fontend/
└── lib/
    └── features/
        └── auth/
            └── data/
                └── services/
                    └── social_login_client.dart
```

**Structure Decision**: Modified `social_login_client.dart` inside the `VFIT_Fontend` project.
