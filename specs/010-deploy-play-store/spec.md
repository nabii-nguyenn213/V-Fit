# Feature Specification: Setup and deploy mobile app to Google Play Store

**Feature Branch**: `010-deploy-play-store`

**Created**: 2026-06-17

**Status**: Draft

**Input**: User description: "bây giờ t muốn cho cái app t lên ch play thì cần setup những cái gì xây aab xogns sao nx tạo cho t 1 bản kế hauchj"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build Signed Android App Bundle (AAB) (Priority: P1)

Developers must be able to securely sign and compile the Flutter app into an Android App Bundle (`.aab`) ready for uploading to the Play Console.

**Why this priority**: Without a signed release binary (AAB), Google Play Console will reject the application package upload.

**Independent Test**: Run the Flutter build command using a release keystore, and verify that `build/app/outputs/bundle/release/app-release.aab` is successfully generated and signed.

**Acceptance Scenarios**:

1. **Given** a valid release keystore and configured `key.properties`, **When** the developer runs `flutter build appbundle --release`, **Then** the build succeeds and outputs a signed AAB file.
2. **Given** missing signing credentials, **When** building the appbundle, **Then** the build fails with a clear signing configuration error.

---

### User Story 2 - Google Play Console App Setup & Content Declaration (Priority: P2)

The publisher must complete all mandatory questionnaire forms, declarations, and store listings in the Google Play Console to make the app visible and conform to Google Play policies.

**Why this priority**: Google requires policy compliance declarations (such as target audience, data safety, ads) and store assets before the app can be distributed.

**Independent Test**: Verify that the Play Console dashboard shows "All tasks completed" for the initial app setup checklist and a Store Listing is fully draft-saved.

**Acceptance Scenarios**:

1. **Given** a new App in Play Console, **When** all content declarations (Privacy Policy, Target Audience, Data Safety, Content Rating) are submitted, **Then** Google Play Console changes status to "Ready to Publish".
2. **Given** missing store assets (e.g., screenshots, icons), **When** trying to publish, **Then** Google Play Console displays validation errors highlighting the missing details.

---

### User Story 3 - Release to Internal Testing & Configure Google OAuth (Priority: P1)

The publisher must upload the AAB to a testing track (such as Internal Testing) and update the Google Cloud OAuth Consent/Client IDs with the new SHA fingerprint to ensure Google Sign-In functions in the production build.

**Why this priority**: Google Play App Signing changes the signing certificate of the app. Google Sign-In will break in production unless the Google-managed production certificate's SHA fingerprint is added to the Google Cloud Console credentials.

**Independent Test**: Download the app from the Play Store Internal Testing track, run it, and verify that Google Sign-In completes successfully.

**Acceptance Scenarios**:

1. **Given** a successfully uploaded AAB in Google Play Console, **When** the app is distributed via Internal Testing, **Then** users can install it on their devices.
2. **Given** the app is downloaded from Google Play, **When** the user clicks "Sign In with Google", **Then** the Google Sign-In flow completes and authenticate the user without errors.

---

### Edge Cases

- **Signing Certificate Mismatch**: When deploying, the local upload key SHA-1 differs from the Google Play App Signing SHA-1. If only the local key is added to Google Cloud Console, Google Sign-In will fail in production. We must update the OAuth credentials with BOTH local and Google Play signing keys.
- **Privacy Policy URL Requirements**: Google Play requires a live, public Privacy Policy URL. We must set up a public webpage hosting the privacy policy.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support release signing configuration via `android/key.properties` (excluded from git tracking).
- **FR-002**: System MUST compile to a single Android App Bundle (`.aab`) target.
- **FR-003**: The app package name MUST remain `com.vfit.vfit_frontend` to preserve identity.
- **FR-004**: System MUST have a public Privacy Policy page served under the main domain (e.g. `https://trungtranvfit.id.vn/privacy-policy.html`).
- **FR-005**: Google Sign-In configuration MUST support both local developers (debug/upload key) and Google Play App Signing certificates (production key).

### Key Entities

- **Keystore**: Cryptographic key file (`upload-keystore.jks`) used to sign the app bundle locally.
- **Play Console App**: The application metadata profile, store listing, and release tracks configured on Google Play.
- **Google OAuth Client Credentials**: Client IDs created in Google Cloud Console mapping the app package name and SHA certificates to authorize Google Sign-In.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Generate a valid, signed Android App Bundle (AAB) file in under 5 minutes of build time.
- **SC-002**: The Google Play Store Internal Test version of the app can be installed on Android devices.
- **SC-003**: Google Sign-In completes successfully on a production-signed build distributed via Google Play.

## Assumptions

- The user has or will register a Google Play Console Developer Account ($25 one-time fee).
- The user has access to the Google Cloud Console associated with the Google Client ID.
- The web backend will host the privacy policy static page.
