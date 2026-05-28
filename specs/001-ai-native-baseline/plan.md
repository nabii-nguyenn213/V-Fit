# Implementation Plan: AI-Native V-FIT Baseline

**Branch**: `001-ai-native-baseline` | **Date**: 2026-05-28 |
**Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-ai-native-baseline/spec.md`

## Summary

Document and govern the current V-FIT system as an AI-native fitness ecosystem.
Keep Flutter as the client, Spring Boot as the gateway, MongoDB and Redis as the
data/protection layer, and `skills/conversation/` as the prompt control plane.

## Technical Context

**Language/Version**: Java 21, Dart SDK >=3.4.0 <4.0.0, Flutter 3.x.

**Primary Dependencies**: Spring Boot 3.3.5, Spring Security, WebSocket,
MongoDB, Redis, Resilience4j, MapStruct, Lombok, JJWT, OpenAPI, Flutter
Riverpod, BLoC, GoRouter, Dio, Hive, Secure Storage, Freezed, FL Chart.

**Storage**: MongoDB for documents, Redis for cache/rate-limit/locks, local or
Cloudinary file storage, secure client token storage, Hive and shared
preferences for local state.

**Testing**: Maven tests for backend; Flutter widget/unit tests for frontend.

**Target Platform**: Mobile-first Flutter app for Android, iOS, and web;
Spring Boot API deployed by Docker Compose behind Nginx.

**Project Type**: Mobile app plus API modular monolith.

**Performance Goals**: AI form feedback MUST remain low-latency enough for
real-time coaching; REST user flows SHOULD respond within standard mobile app
expectations; payment status MUST update before payment expiry.

**Constraints**: AI endpoints MUST be authenticated, premium-gated,
rate-limited, upload-limited, circuit-breaker protected, and typed before
client display.

**Scale/Scope**: Current baseline covers auth, onboarding, profile, workouts,
exercise library, nutrition, AI, progress, gamification, payment, admin, and app
config.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- AI-Native Control Plane: PASS. AI flows are centralized through `AiClient`.
- Prompt Governance: PASS. `skills/conversation/system.prompt.md` is created as
  the initial prompt authority.
- Data Boundary Discipline: PASS. AI output is bounded by DTO contracts and
  fallback semantics.
- Observable Modular Monolith: PASS. Backend remains module-oriented with
  security, infrastructure, and feature packages.
- Premium Safety Gates: PASS. Premium AI is gated by onboarding, JWT,
  subscription, rate limits, and circuit breakers.

## Project Structure

### Documentation

```text
specs/
|-- constitution.md
|-- baseline.md
|-- specify.md
|-- plan.md
`-- 001-ai-native-baseline/
    |-- spec.md
    |-- plan.md
    |-- research.md
    |-- data-model.md
    |-- quickstart.md
    |-- checklists/
    |   `-- requirements.md
    `-- contracts/
        `-- ai-contracts.md
```

### Source Code

```text
VFIT_Backend/
|-- src/main/java/com/vfit/
|   |-- common/
|   |-- security/
|   |-- infrastructure/
|   |-- bootstrap/
|   `-- modules/
|       |-- ai/
|       |-- app/
|       |-- auth/
|       |-- checkin/
|       |-- exercise/
|       |-- exercise_library/
|       |-- gamification/
|       |-- nutrition/
|       |-- payment/
|       |-- personalized_workout/
|       |-- progress/
|       |-- subscription/
|       `-- user/
`-- src/test/java/com/vfit/

VFIT_Fontend/
|-- lib/
|   |-- core/
|   |-- features/
|   `-- presentation/
`-- test/

skills/
|-- conversation/
|   `-- system.prompt.md
`-- tech-decision/
    `-- decision.md
```

**Structure Decision**: Keep the existing mobile-plus-API layout. Add Spec Kit
and prompt governance files without moving application code.

## Prompt Chaining Architecture

```text
Flutter UI
-> REST or WebSocket request
-> Spring Security JWT filter
-> OnboardingGuardFilter
-> FeatureGate for premium AI
-> AiRateLimitFilter
-> Controller
-> Service
-> AiClient
-> skills/conversation prompt contract
-> AI Core or MockAiClient
-> DTO parser
-> ApiResponse or WebSocket feedback
-> Flutter state manager
-> User-facing UI
```

## 24/7 Runtime Operation

- Schedulers clean expired accounts, payments, and vouchers.
- Redis protects AI requests and payment actions continuously.
- WebSocket handlers process form-check frames during active sessions.
- Sepay webhook updates payment state asynchronously.
- Circuit breakers keep AI flows responsive during provider failure.
- App config and seed data allow the app to boot without hardcoded UI data.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | Not applicable | Not applicable |
