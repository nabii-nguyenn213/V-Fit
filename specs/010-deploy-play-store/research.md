# Technical Research: Google Play Store Deployment Configuration

This document covers research and design decisions for signing the Android app, mapping OAuth client credentials, and policy compliance.

## 1. Keystore Management and Signing Configuration

### Decision
Use an external `key.properties` file located in `VFIT_Fontend/android/` to store the keystore path, alias, and passwords. This file is read dynamically by `VFIT_Fontend/android/app/build.gradle`.

### Rationale
- Security: Keeps credentials out of version control.
- Git Safety: Both `key.properties` and the `.jks` keystore file are added to `.gitignore`.
- Portability: Different developers can maintain their own signing setups by changing their local `key.properties`.

### Alternatives Considered
- **Hardcoding signing credentials in build.gradle**: Rejected as highly insecure. Credentials would be pushed to the public/shared repository.
- **Passing signing parameters via CLI parameters during build**: Rejected due to inconvenience and risk of exposing credentials in shell history logs.

---

## 2. Google Sign-In and Google Play App Signing Integration

### Decision
Register **two** separate Android OAuth client credentials in Google Cloud Console:
1. One with the local upload key SHA-1/SHA-256 fingerprint (used for local testing and debugging).
2. One with the **Google Play App Signing certificate** SHA-1/SHA-256 fingerprint (downloaded from Google Play Console under **Setup > App Integrity**).

### Rationale
- When releasing an AAB to the Play Store, Google removes the local upload key signature and re-signs the app with a secure production key managed by Google.
- If only the local upload key signature is registered in Google Cloud Console, Google Sign-In will fail with API Error Code 10/12500 when users download the app from Google Play.

### Alternatives Considered
- **Opting out of Google Play App Signing**: Google Play Console no longer allows opting out of Play App Signing for new apps. Therefore, this alternative is not feasible.

---

## 3. Privacy Policy Page Hosting

### Decision
Serve the Privacy Policy as a static HTML page `privacy-policy.html` from the Spring Boot backend static assets. It will be served at `https://trungtranvfit.id.vn/privacy.html` or `/privacy-policy.html`.

### Rationale
- Simple setup: Reuses the existing backend Caddy / Spring Boot static asset serving pipelines.
- Zero extra costs or dependencies.

### Alternatives Considered
- **Third-party privacy policy generators / hosting services**: Rejected as it adds external dependencies and could lead to links expiring or changing.
