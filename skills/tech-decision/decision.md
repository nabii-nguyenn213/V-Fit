# Architectural Decision Record

## Status

Accepted.

## Product Decision

V-FIT MUST operate as an AI-native fitness ecosystem. AI MUST drive coaching,
recommendations, body analysis, form feedback, food calorie estimation, and
adaptive guidance. Deterministic code MUST guard identity, permissions, data
shape, persistence, payments, and operational safety.

## Current Stack

- Frontend MUST remain Flutter 3/Dart 3 with Riverpod, BLoC, GoRouter, Dio,
  Hive, SharedPreferences, Secure Storage, Freezed, JSON Serializable, SVG,
  Image Picker, FL Chart, Firebase Crashlytics, and Material UI.
- Backend MUST remain Java 21 and Spring Boot 3.3 modular monolith.
- Backend MUST use Spring Web, WebSocket, Security, Validation, Data MongoDB,
  Data Redis, Cache, AOP, Actuator, Mail, OpenAPI, Resilience4j, Lombok,
  MapStruct, JJWT, and Logstash logging.
- Data MUST remain MongoDB-first with document models and flexible AI payload
  maps.
- Redis MUST serve cache, AI rate limiting, and payment/voucher locking.
- Storage MUST support local uploads and Cloudinary.
- Payments MUST support Sepay webhook, VietQR, vouchers, premium plans, and
  payment WebSocket status.
- Deployment MUST use Docker Compose, Nginx production config, and environment
  driven secrets.
- Testing MUST use Maven tests for backend and Flutter tests for frontend.

## AI-Native Architecture

- AI Core access MUST go through `com.vfit.infrastructure.external.ai.AiClient`.
- Current AI capabilities MUST include `analyzeForm`, `analyzeBody`, and
  `estimateFoodCalories`.
- The backend MUST own fallback semantics through Resilience4j circuit breakers.
- The backend MUST transform raw AI maps into typed DTOs before returning them.
- AI endpoints MUST be protected by JWT, onboarding state, premium feature gate,
  upload limits, Redis rate limiting, and clear error envelopes.

## Prompt Storage

- Runtime prompts MUST live in `skills/conversation/`.
- `skills/conversation/system.prompt.md` MUST define the global AI behavior.
- Additional prompt files MAY split by flow, but MUST declare input contract,
  output contract, safety rules, and fallback behavior.
- App behavior MUST NOT depend on prompt text stored in random docs, comments,
  or database seeders.

## Architecture Ownership

- This file MUST remain the source of truth for architectural decisions.
- Spec Kit files MUST describe product scope and implementation plan.
- OpenSpec files MAY remain historical context for muscle-map changes.
- Code MUST follow existing feature-module boundaries.
