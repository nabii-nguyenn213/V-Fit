<!--
Sync Impact Report
Version change: 1.0.0 -> 1.1.0
Modified principles:
- I. AI-Native Control Plane: unchanged
- II. Prompt Governance: unchanged
- III. Data Boundary Discipline: unchanged
- IV. Observable Modular Monolith: unchanged
- V. Premium Safety Gates: unchanged
- New principle -> VI. Authentication Identity Integrity
Added sections:
- None
Removed sections:
- None
Templates requiring updates:
- .specify/templates/plan-template.md: updated
- .specify/templates/spec-template.md: reviewed, no change required
- .specify/templates/tasks-template.md: updated
- .specify/templates/checklist-template.md: reviewed, no change required
- .specify/templates/commands/*.md: not present
- .specify/extensions.yml: reviewed, no change required
- AGENTS.md: reviewed, no change required
- CLAUDE.md: reviewed, no change required
- FEATURES.md: reviewed, no change required
Follow-up TODOs:
- None
-->
# V-FIT Constitution

## Core Principles

### I. AI-Native Control Plane
The system MUST treat AI as the decision layer for coaching, recommendation,
analysis, and adaptive user guidance. Product logic that depends on reasoning,
fitness interpretation, nutrition estimation, form feedback, or body analysis
MUST enter through an explicit AI contract. Deterministic backend code MUST
authenticate, validate, rate-limit, persist, and audit the AI interaction.

Rationale: V-FIT exists as an AI-driven fitness ecosystem. AI decisions must be
first-class, bounded, and inspectable instead of hidden inside UI branches.

### II. Prompt Governance
All runtime prompts MUST live under `skills/conversation/`. Architectural
decisions MUST live under `skills/tech-decision/decision.md`. Prompt changes
MUST be reviewed like source code, include purpose and output contract, and avoid
embedding production secrets or uncontrolled user data.

Rationale: Prompts are application logic in this project. They require the same
ownership, versioning, and review discipline as Java and Dart code.

### III. Data Boundary Discipline
Every AI input MUST be minimized, normalized, and authorized before model use.
Every AI output MUST be parsed into a typed contract, assigned confidence or
fallback semantics when applicable, and rejected when it violates safety,
subscription, onboarding, or schema rules. Raw AI output MUST NOT directly drive
payments, account state, permissions, or destructive actions.

Rationale: Fitness, body, payment, and account data are sensitive. The system
must control both what enters AI and what leaves AI.

### IV. Observable Modular Monolith
The backend MUST remain a modular Spring Boot monolith with clear module
boundaries, API envelopes, explicit services, repositories, mappers, and domain
events. Cross-module communication SHOULD prefer Spring events for loose
coupling. Runtime paths MUST expose logs, health, rate-limit behavior, circuit
breaker fallback, and meaningful error responses.

Rationale: The current architecture supports speed while preserving future
extractability and operational clarity.

### V. Premium Safety Gates
Premium AI capabilities MUST require completed onboarding and active VIP
subscription unless the endpoint is explicitly part of onboarding. AI endpoints
MUST enforce JWT identity, feature gates, Redis-backed rate limiting, upload
limits, and graceful fallback when external AI is unavailable.

Rationale: AI features are costly, sensitive, and central to paid value.
Access control and failure behavior must be non-negotiable.

### VI. Authentication Identity Integrity
The authentication surface MUST support email/password plus Google and Facebook
sign-in as first-class login methods. External provider tokens MUST be verified
server-side before account creation, login, or linking. The backend MUST map
provider identities to one canonical V-FIT user, issue only V-FIT JWTs to
clients, audit login/link/unlink events, and prevent duplicate accounts for the
same verified email or provider subject. Provider outages, denied consent,
missing email claims, disabled users, and already-linked identities MUST return
explicit, non-destructive error responses.

Rationale: Social login reduces onboarding friction, but identity providers must
not become uncontrolled account authorities inside the product.

## Runtime Architecture Rules

- Keep Flutter as the primary mobile client and Spring Boot as the API gateway.
- Keep MongoDB as the document store for users, catalogs, AI payloads, progress,
  payments, subscriptions, and app configuration.
- Keep Redis for cache, rate limiting, and short-lived payment locks.
- Keep `AiClient` as the backend boundary to AI Core.
- Keep WebSocket for low-latency form-check feedback.
- Keep REST contracts for auth, onboarding, profile, workouts, nutrition,
  progress, payments, gamification, admin, and app config.
- Keep all prompt-chain definitions in `skills/conversation/`.
- Keep Google and Facebook login behind backend provider verification, canonical
  account linking, V-FIT JWT issuance, and security audit events.

## Development Workflow

- Create or claim work with `bd` before changing files.
- Read the active Spec Kit plan before implementation.
- Update specs before changing behavior.
- Add or update tests when code changes affect contracts, security, AI
  boundaries, payment state, or user-visible flows.
- Run the relevant quality gate before closing work.
- Commit and push code and beads data before ending a session.

## Governance

This constitution supersedes conflicting project notes. Amendments MUST update
this file, the Sync Impact Report, affected Spec Kit templates, and any runtime
guidance files. Versioning follows semantic rules: MAJOR for incompatible
principle changes, MINOR for new or materially expanded principles, and PATCH
for clarification. Compliance MUST be checked during specification, planning,
review, and release handoff.

**Version**: 1.1.0 | **Ratified**: 2026-05-28 | **Last Amended**: 2026-06-02
