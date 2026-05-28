# VFIT Architectural Decision Record

## Status

Accepted.

## Scope

This file is the source of truth for core technology decisions in VFIT. Any
change to language, framework, database, AI boundary, prompt storage, payment
flow, realtime channel, or deployment model MUST update this file first.

## Current Technology Stack

### Backend

- Language: Java 21.
- Framework: Spring Boot 3.3.5 modular monolith.
- Web: Spring MVC REST controllers.
- Realtime: Spring WebSocket with raw binary/text handlers.
- Security: Spring Security 6, JWT, refresh tokens, OTP, route guards,
  onboarding guard, premium feature gate, and password hashing.
- Validation: Jakarta Validation through DTO request classes.
- Persistence: MongoDB through Spring Data MongoDB.
- Cache and volatile state: Redis through Spring Data Redis and Spring Cache.
- AI resilience: Resilience4j circuit breaker on `AiClient`.
- API docs: springdoc OpenAPI and Swagger UI.
- Mapping: MapStruct.
- Boilerplate reduction: Lombok.
- Logging: Logback with logstash encoder.
- Mail: Spring Mail for OTP and password reset flows.
- File storage: local upload service and Cloudinary service.
- Payment: Sepay webhook, VietQR QR generation, vouchers, premium plans, and
  payment WebSocket updates.
- Packaging and deployment: Maven, Dockerfile, Docker Compose, Nginx config.

### Frontend

- Language: Dart with SDK constraint `>=3.4.0 <4.0.0`.
- Framework: Flutter mobile-first app with Android, iOS, and web targets.
- State management: Riverpod and BLoC.
- Routing: GoRouter.
- HTTP client: Dio with auth interceptor, token refresh, timeout policy, and
  optional certificate pinning.
- Secure storage: Flutter Secure Storage for tokens.
- Local state: SharedPreferences and Hive.
- Data models: JSON Serializable, Freezed, Equatable.
- Media and visuals: Image Picker, Flutter SVG, XML parser, path_drawing,
  Google Fonts, FL Chart.
- Crash reporting: Firebase Crashlytics.
- Tests: Flutter test and flutter_lints.

### Data Stores

- MongoDB stores users, sessions, OTP/reset tokens, app config, workouts,
  exercises, foods, AI analysis documents, progress snaps, challenges, badges,
  vouchers, payment transactions, and subscriptions.
- Redis stores AI rate-limit counters, caches, and short-lived payment locks.
- Flutter local storage stores secure tokens, lightweight preferences, and
  cached feature data.

## AI-Driven Architecture

VFIT is an AI-driven fitness system. AI is the reasoning layer for body
analysis, realtime form feedback, food calorie estimation, workout
personalization, coaching language, risk flags, and adaptive recommendations.

The backend MUST keep deterministic control over authentication, authorization,
rate limits, payment state, subscription state, data validation, persistence,
and audit logs. AI MUST NOT directly mutate user accounts, payments,
permissions, subscriptions, or destructive state.

## AI Boundary

All backend calls to intelligent processing MUST go through:

`com.vfit.infrastructure.external.ai.AiClient`

Current AI methods:

- `analyzeForm(userId, videoUrl, metadata)`
- `analyzeBody(userId, imageUrl, metadata)`
- `estimateFoodCalories(imageReference, metadata)`

Current implementation:

- `MockAiClient` returns deterministic mock AI outputs.
- Resilience4j fallback methods return safe degraded responses.
- Service classes convert raw AI maps into controlled response DTOs where
  available.

Future production AI providers MUST implement `AiClient` and preserve the same
input, output, fallback, logging, and security contract.

## Prompt Storage Decision

All system prompts, flow prompts, output schemas, context rules, and safety
rules MUST live under:

`skills/conversation/`

The global prompt is:

`skills/conversation/system.prompt.md`

Prompt files are application logic. They MUST be reviewed, versioned, tested
against sample inputs, and kept free of secrets. Prompt changes MUST declare:

- Flow owner.
- Input contract.
- Output contract.
- Context required.
- Refusal and fallback rules.
- Data retention and privacy constraints.

## Context Synchronization Decision

VFIT context is synchronized through layered state:

- Backend source of truth: MongoDB user, subscription, progress, AI analysis,
  payment, and catalog documents.
- Volatile runtime state: Redis counters, locks, and caches.
- Client session state: secure token storage, SharedPreferences, Hive, Riverpod,
  and BLoC states.
- AI prompt context: prompt files under `skills/conversation/` plus runtime
  metadata sent through `AiClient`.

No RabbitMQ, Kafka, JMS, or external queue broker is present in the current
codebase. Async behavior currently uses Spring application events, `@Async`
listeners, schedulers, webhooks, and WebSocket pushes.

## Communication Decisions

### Sync

Use REST for request-response flows:

- Auth, OTP, login, refresh, logout, forgot/reset password.
- Onboarding profile, onboarding metrics, body scan.
- User profile, avatar, body metrics, sessions, account deletion.
- App config, workouts, exercises, grouped exercise library, foods.
- Progress snaps, check-in, badges, challenges, challenge participation.
- Premium payment creation, payment status, VIP status, voucher, checkout.
- Admin users, app config, dashboard, monthly revenue, transactions.

### Async

Use asynchronous mechanisms already present in code:

- Spring `ApplicationEventPublisher` for registration and progress events.
- `@Async @EventListener` for mapping progress photos into active challenges.
- `@Scheduled` cleanup for expired auth artifacts, inactive accounts, pending
  payments, and expired vouchers.
- Sepay webhook for external bank payment confirmation.
- WebSocket `/ws/payments` for payment paid notifications.
- WebSocket `/ws/ai/form-check` for realtime binary camera frame feedback.

## Security Decisions

- JWT access tokens MUST guard protected API routes.
- Refresh tokens MUST be stored and rotated through backend auth flows.
- Pending onboarding users MUST be blocked from protected customer features.
- Premium AI MUST require active VIP subscription.
- AI endpoints MUST be rate-limited through Redis.
- Upload size MUST remain constrained by Spring multipart limits.
- Sepay webhooks MUST verify HMAC signature and timestamp.
- Admin routes MUST remain separate from customer routes.

## Naming Decision

The repository currently uses `VFIT_Fontend` as the frontend folder name. Specs
MUST reference the actual folder name until the project performs a coordinated
rename.
