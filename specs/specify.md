# VFIT Specify

## Active Baseline

Use `specs/baseline.md` as the complete current-system feature specification.

## Active Feature Directory

Use `specs/001-ai-native-baseline/` for Spec Kit generated planning artifacts.

## Required Behavior

All future specifications MUST preserve the AI-driven model:

- Backend owns trusted state and security boundaries.
- Frontend owns user interaction and local presentation state.
- AI Core owns reasoning only through `AiClient` and prompt contracts.
- Prompts live under `skills/conversation/`.
- Architecture decisions live under `skills/tech-decision/decision.md`.

## Existing Flows Covered

- Auth and OTP.
- Onboarding and body scan AI.
- Profile and body metrics.
- Workout and exercise catalogs.
- Personalized workout.
- Nutrition search and AI food estimate.
- Progress snaps and challenge mapping.
- Gamification.
- Daily check-in and voucher rewards.
- Premium payment, Sepay webhook, VietQR, payment WebSocket, VIP status.
- Admin users, app config, dashboard, and revenue.
