# VFIT Constitution

## Authority

This constitution governs VFIT. It overrides informal notes when architecture,
AI behavior, security, data handling, or delivery workflow conflicts.

## Principle 1: AI Is The Reasoning Layer

VFIT MUST operate as an AI-driven fitness system. AI MUST handle intelligent
analysis, coaching, form feedback, body interpretation, food estimation,
recommendation, and personalization. Deterministic code MUST own identity,
permissions, payment, subscription, persistence, and audit boundaries.

## Principle 2: Prompts Are Source Code

All prompts that influence app behavior MUST live under `skills/conversation/`.
Prompt files MUST use explicit input contracts, output contracts, safety rules,
context rules, and fallback rules. Prompts MUST NOT be scattered through random
docs, comments, database seeders, or UI text.

## Principle 3: Technology Decisions Are Centralized

Core technology decisions MUST be recorded in
`skills/tech-decision/decision.md`. Developers and agents MUST update that file
before changing framework, database, AI provider, queue strategy, deployment
runtime, auth model, or payment integration.

## Principle 4: User Data Is Sensitive

VFIT handles body metrics, progress photos, AI analysis, payment data, and
account data. The system MUST minimize AI inputs, avoid unnecessary personal
data transfer, never send secrets to AI, and keep raw user media behind
authorized backend flows.

## Principle 5: AI Input Must Be Controlled

Before data reaches AI, the backend MUST authenticate the actor, verify
onboarding and premium rules when required, validate upload shape, attach only
necessary metadata, apply rate limiting, and record enough context for audit.

## Principle 6: AI Output Must Be Controlled

AI output MUST be parsed into bounded contracts before it reaches Flutter or
persistent state. AI output MUST include confidence or fallback semantics where
analysis is uncertain. AI output MUST NOT directly alter payments,
subscriptions, roles, sessions, account deletion, or admin state.

## Principle 7: Sync And Async Paths Must Be Explicit

REST request-response flows MUST remain clear and typed. Async flows MUST be
named as one of: Spring event, `@Async` listener, scheduler, webhook, Redis
runtime state, or WebSocket push. The current codebase MUST NOT claim RabbitMQ
or external queue usage until such infrastructure exists.

## Principle 8: Premium AI Must Be Gated

AI form check, standalone AI nutrition scan, and future premium analysis flows
MUST require completed onboarding, authenticated user identity, active VIP
subscription, Redis rate limiting, and fallback behavior. Onboarding body scan
is the only allowed AI exception for pending users.

## Principle 9: Modular Monolith Boundaries Must Hold

The backend MUST remain a modular monolith with `common`, `security`,
`infrastructure`, `bootstrap`, and `modules/*` boundaries. Feature modules MUST
communicate through services, repositories, mappers, events, DTOs, and API
envelopes instead of reaching across unrelated implementation details.

## Governance

Every feature, refactor, and agent task MUST check this constitution. Any
change that weakens an AI, auth, payment, privacy, or data boundary MUST be
documented before implementation. This document is maintained in Markdown ATX
format and MUST contain concrete project rules only.
