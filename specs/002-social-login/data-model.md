# Data Model: Google And Facebook Login

## Social Login Request

Fields: provider, provider token, optional nonce, platform.

Validation: Provider MUST be `GOOGLE` or `FACEBOOK`. Provider token MUST be
present. Backend MUST reject unknown providers before verification.

## Social Provider Identity

Fields: id, user id, provider, provider subject, verified email, display name,
avatar URL, linked time, last login time.

Relationships: Belongs to one canonical V-FIT user. Provider plus provider
subject MUST be unique.

Validation: Raw provider tokens MUST NOT be stored. Missing verified email MUST
be rejected unless a future explicit no-email linking flow is specified.

## User

Fields impacted: email, full name, avatar, role, active flag, onboarding status,
provider identity links, created time, updated time.

Relationships: Owns social provider identities, sessions, refresh tokens,
progress, payments, and subscriptions.

Validation: Email remains normalized and unique. Disabled users MUST NOT receive
tokens. New social users MUST enter the same onboarding flow as new local users.

## Auth Event

Fields: event id, user id when known, provider, event type, result, reason,
request metadata, created time.

Relationships: MAY reference user and provider identity.

Validation: Events MUST NOT store raw provider tokens or secrets.
