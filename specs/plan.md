# Plan

## Rule

Use `specs/001-ai-native-baseline/plan.md` as the active implementation plan.

## Prompt Chain

Flutter UI MUST call Spring Boot through REST or WebSocket. Spring Boot MUST
authenticate, enforce onboarding, enforce premium feature gates, rate-limit AI,
call `AiClient`, parse output, persist state, and return typed responses.

## Runtime Loop

V-FIT MUST keep AI flows ready 24/7 through API availability, WebSocket handlers,
schedulers, Redis protection, payment webhooks, circuit breakers, and fallback
responses.
