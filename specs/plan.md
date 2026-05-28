# VFIT Implementation Plan

## Summary

VFIT operates as a Flutter client plus Spring Boot modular monolith. The
backend is the trusted gateway for identity, user data, payment, storage,
subscription, rate limits, and AI provider access. AI-driven logic is centralized
through prompt files under `skills/conversation/` and the backend `AiClient`
boundary.

## Architecture

```text
Flutter UI
-> Riverpod or BLoC state
-> Dio REST call or WebSocket stream
-> Spring Security and filters
-> Controller
-> Service
-> Repository, Redis, storage, payment, or AiClient
-> MongoDB durable state
-> API envelope or WebSocket event
-> Flutter state update
```

## Prompt Chaining

Prompt chaining MUST follow this order:

1. `system.prompt.md` defines global role, safety, privacy, and output rules.
2. Flow prompt defines the exact AI task: body analysis, form check, food
   estimate, recommendation, or coaching.
3. Context builder supplies only allowed user, exercise, payment, progress, or
   nutrition metadata.
4. AI provider returns structured output.
5. Backend parser validates fields, confidence, fallback flags, and business
   constraints.
6. Backend stores only approved durable context.
7. Flutter displays user-facing coaching or state changes.

## Sync Communication

Synchronous communication uses REST and API envelopes.

- Flutter Dio sends JSON or multipart requests.
- `AuthInterceptor` attaches access token for protected routes.
- `AuthInterceptor` refreshes token on eligible `401` responses.
- Spring controllers return `ApiResponse` or `ErrorResponse`.
- MongoDB stores authoritative records.
- Redis MAY be used for cache, lock, or rate-limit decisions during the request.

Primary sync domains:

- Auth and OTP.
- User profile and onboarding.
- App config.
- Workouts and exercises.
- Food search.
- AI food estimate.
- Progress snap CRUD.
- Check-in.
- Voucher, checkout, premium payment, VIP status.
- Admin dashboard and app config.

## Async Communication

The current repo has no RabbitMQ, Kafka, JMS, or external queue broker. Async is
implemented with in-process and protocol-level mechanisms.

### Spring Event Queue

Spring application events are the current internal queue. `JourneySnapService`
publishes `ProgressPhotoUploadedEvent`; `ProgressPhotoUploadedListener` consumes
it with `@Async` and maps the uploaded photo to active challenges.

### Webhook Queue

Sepay acts as the external async payment source. The webhook endpoint verifies
HMAC, rejects suspicious payloads, ignores duplicates, marks valid transactions
paid, unlocks subscription, and emits payment WebSocket events.

### Scheduler Queue

Schedulers poll durable state on fixed intervals or cron:

- Auth cleanup.
- Account cleanup.
- Payment expiry.
- Voucher expiry.

### WebSocket Streams

`/ws/ai/form-check` receives binary camera frames and returns AI feedback.
`/ws/payments` pushes payment paid events to connected Flutter clients.

## dAbbit Context

The project does not contain a concrete service named `dAbbit`. For the current
codebase, `dAbbit context` means the shared AI operating context composed of:

- MongoDB durable context: user profile, body metrics, subscription, progress,
  AI analysis, payment, challenge, workout, food, and app config documents.
- Redis volatile context: AI rate-limit counters, payment locks, and cache.
- Flutter client context: secure tokens, local preferences, Hive caches,
  Riverpod providers, and BLoC states.
- Prompt context: files under `skills/conversation/`.
- Request metadata: endpoint, user id, exercise id, upload metadata, frame size,
  payment code, and current goal.

No file may claim RabbitMQ or external queue usage until code and deployment
configuration introduce it.

## AI Runtime Plan

- Keep `AiClient` as the only backend interface to AI.
- Keep `MockAiClient` as local fallback and testable stand-in.
- Add production AI provider behind `AiClient` without exposing provider keys to
  Flutter.
- Add flow-specific prompts under `skills/conversation/` when implementation
  moves beyond the current global system prompt.
- Parse all AI outputs before returning to Flutter.
- Persist AI result context only after schema and safety checks.

## Quality Gates

- Spec Kit files contain concrete project-specific content.
- No inaccurate queue or broker claim.
- AI endpoints remain gated, rate-limited, and fallback-safe.
- Payment webhook remains idempotent and signed.
- Frontend routes remain consistent with backend endpoint constants.
