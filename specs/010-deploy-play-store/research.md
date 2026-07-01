# Research: Registration 7-Day VIP Trial and Profile Redesign

## VIP Trial Plan Registration Logic
- **Decision**: Newly registered users will be given a subscription snapshot with planCode `"VIP_TRIAL"`, status `ACTIVE`, and `premiumUntil` set to `now + 7 days`.
- **Rationale**: This seamlessly integrates with the existing premium gate and subscription mechanics without requiring complex DB migration or external billing triggers.
- **Alternatives considered**:
  1. Integrating an actual billing trial via payment gateway (rejected: requires payment credential upfront, which adds high friction).
  2. Creating a separate role for trial users (rejected: violates modularity, isPremium check is already based on subscription status).

## UI Accent Fixes
- **Decision**: Update all label string literals in `edit_profile_page.dart` to use UTF-8 accented Vietnamese.
- **Rationale**: Accented letters in Dart/Flutter source files are stored as UTF-8, which resolves font issues when compiled/bundled correctly on Android/iOS.
- **Alternatives considered**:
  1. Setting up dynamic localized JSON files (rejected: overkill for a single page edit and adds unnecessary dependency).

## Onboarding Metrics Redirection
- **Decision**: The backend will return a custom `ONBOARDING_REQUIRED` error code when pending onboarding users query gated APIs. The frontend will catch this and display a redirect button.
- **Rationale**: Correctly distinguishes between a user who is not VIP and a user who just hasn't completed onboarding, avoiding false VIP upgrade prompts.
- **Alternatives considered**:
  1. Silently returning empty metrics (rejected: user gets no feedback on why metrics are blank).
