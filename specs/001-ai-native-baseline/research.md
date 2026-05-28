# Research: AI-Native V-FIT Baseline

## Decision: Keep Spring Boot Modular Monolith

Rationale: The backend already separates `common`, `security`,
`infrastructure`, and feature modules. This keeps delivery fast while allowing
future extraction through events and clear module contracts.

Alternatives considered: Split microservices now. Rejected because current code,
deployment, and tests are monolith-oriented.

## Decision: Keep Flutter As Primary Client

Rationale: The current app implements auth, onboarding, home, workouts,
nutrition, progress, profile, premium, admin, and revenue routes with shared
theme and network layers.

Alternatives considered: Separate web admin. Rejected for baseline because admin
routes already exist in Flutter.

## Decision: Keep AI Behind `AiClient`

Rationale: Current AI flows already use a single backend boundary with
Resilience4j fallback. This is the correct insertion point for production AI
Core and prompt-chain enforcement.

Alternatives considered: Call AI directly from Flutter. Rejected because it
would bypass auth, rate limits, subscriptions, and output validation.

## Decision: Store Prompts Under `skills/conversation/`

Rationale: The user explicitly requires prompts to control the app. Centralized
prompt files make AI behavior reviewable, versioned, and portable.

Alternatives considered: Store prompts in code comments or database config.
Rejected because they fragment ownership and weaken review discipline.

## Decision: Keep MongoDB And Redis

Rationale: MongoDB fits the existing document models and flexible AI payloads.
Redis already supports cache, AI rate limiting, and payment locks.

Alternatives considered: Move flexible AI payloads to SQL immediately. Rejected
because no current migration requires relational constraints.
