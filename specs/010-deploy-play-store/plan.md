# Implementation Plan: Google Play Store Deployment

**Branch**: `010-deploy-play-store` | **Date**: 2026-06-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-deploy-play-store/spec.md`

## Summary

This plan covers configuring release signing for the Android app, building the signed Android App Bundle (AAB), creating the store listing/policy content on Google Play Console, and linking the production SHA-1 fingerprint with Google Cloud Console OAuth credentials to ensure Google Sign-In works correctly in the Google Play release.

## Technical Context

**Language/Version**: Flutter 3.41.9, Dart 3.11.5, Gradle 8.0, Java 17

**Primary Dependencies**: `google_sign_in` (Flutter package), Android Gradle Plugin (AGP)

**Storage**: N/A

**Testing**: Manual installation via Google Play Internal Testing track, and verification of Google Sign-in on a production build.

**Target Platform**: Android (API 21+)

**Project Type**: Mobile App (Flutter Frontend)

**Performance Goals**: Release AAB package successfully built within 5 minutes.

**Constraints**: Package name must match `com.vfit.vfit_frontend`. Signing key must be stored securely and excluded from Git.

**Scale/Scope**: Android platform distribution.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Validate the active plan against the V-FIT constitution:

- **Authentication changes preserve canonical V-FIT user identity**: Pass. Google OAuth login flow on the mobile client sends the Google ID token to the backend, where it is verified and parsed into the canonical V-FIT JWT.
- **OAuth/API client mappings**: Pass. The production build certificate (Google Play App Signing key) must be added to Google Cloud Console to ensure identity verification succeeds in production.

## Project Structure

### Documentation (this feature)

```text
specs/010-deploy-play-store/
├── plan.md              # This file
├── research.md          # Keystore and signing config research
├── data-model.md        # N/A (No DB entities added)
├── quickstart.md        # Quickstart build instructions
└── checklists/
    └── requirements.md  # Spec checklist
```

### Source Code (repository root)

We will modify or reference settings in the following paths:
```text
VFIT_Fontend/
├── android/
│   ├── app/
│   │   ├── build.gradle  # Signing configurations
│   │   └── src/          # Android Manifest / config
│   ├── key.properties    # Credentials (excluded from git)
│   └── upload-keystore.jks # Local Keystore (excluded from git)
└── pubspec.yaml          # Version and package configurations
```

**Structure Decision**: Option 3 (Mobile + API) since this task is purely configuring the Flutter Android app.

## Complexity Tracking

No violations of the constitution.
