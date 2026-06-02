# V-FIT AI Agent Guide

## Purpose

This guide is the operating manual for AI agents working in V-FIT. It merges
the local project rules, Beads issue tracking, OpenSpec change workflow,
Superpowers working discipline, Flutter best practices, and Taste Skill UI/UX
principles into one project-specific workflow.

Agents MUST adapt every recommendation to V-FIT's actual architecture:

- Backend: `VFIT_Backend/`, Java 21, Spring Boot 3.3.5 modular monolith,
  MongoDB, Redis, Spring Security, WebSocket, Resilience4j, MapStruct, Lombok.
- Frontend: `VFIT_Fontend/`, Flutter 3.x, Dart `>=3.4.0 <4.0.0`, Material 3,
  Riverpod, BLoC, GoRouter, Dio, Hive, Secure Storage, Freezed, FL Chart.
- AI control plane: `skills/conversation/`.
- Architecture decisions: `skills/tech-decision/decision.md`.
- Planning artifacts: `specs/` and `openspec/`.
- Issue tracking: Beads through `bd`.

No project-local Flutter `SKILL.md` files were found under `skills/`,
`.agents/`, `.claude/`, or `.specify/` at the time this guide was written, so
Flutter guidance here is based on the installed project stack and the current
Flutter source structure.

## Non-Negotiable Rules

1. Use Beads for task tracking. Run `bd prime` at session start, create or
   claim a relevant issue before work, and close/update it before handoff.
2. Read project context before changing anything: `AGENTS.md`,
   `specs/001-ai-native-baseline/plan.md`, `specs/constitution.md`, and
   `skills/tech-decision/decision.md`.
3. For deploy-sensitive code, read `docs/DEPLOY_ARCHITECTURE_RULES.md`.
4. Do not modify source code for documentation-only requests.
5. Do not bypass the V-FIT AI boundary. All intelligent backend work MUST go
   through `com.vfit.infrastructure.external.ai.AiClient`.
6. Do not scatter prompts. Prompts, output schemas, context rules, and fallback
   rules belong under `skills/conversation/`.
7. Do not change core technology choices without first updating
   `skills/tech-decision/decision.md`.
8. Treat body metrics, progress photos, food images, AI analysis, payment data,
   tokens, and account state as sensitive.
9. Verify before claiming completion. Fresh command output is required for any
   statement that tests, lint, build, or behavior pass.

## Project Mental Model

V-FIT is an AI-native fitness ecosystem. Flutter is the customer and admin
client. Spring Boot is the deterministic gateway. MongoDB stores durable domain
documents. Redis protects volatile flows such as AI rate limits and payment
locks. AI is a reasoning layer, not an authority.

The critical runtime path is:

```text
Flutter UI
-> REST or WebSocket
-> JWT authentication
-> onboarding guard
-> premium feature gate when required
-> Redis rate limit or lock
-> controller
-> service
-> AiClient when intelligence is needed
-> bounded DTO/parser/fallback
-> ApiResponse or WebSocket event
-> Flutter state manager
-> user-facing UI
```

The backend owns identity, authorization, onboarding, payment state,
subscription state, persistence, validation, and audit logs. AI may produce
fitness reasoning, coaching language, risk flags, estimates, and summaries, but
it MUST NOT mutate roles, subscriptions, payments, sessions, or destructive
account state.

## Folder Map

Use existing boundaries:

```text
VFIT_Backend/
|-- src/main/java/com/vfit/
|   |-- common/              shared API envelopes, exceptions, enums, utilities
|   |-- security/            JWT, filters, onboarding, premium gates
|   |-- infrastructure/      config, storage, external AI/payment clients
|   |-- bootstrap/           seeders and storage bootstrap
|   `-- modules/             feature modules
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

VFIT_Fontend/
|-- lib/
|   |-- core/                router, network, theme, widgets, constants
|   |-- features/            auth, onboarding, home, workout, nutrition, etc.
|   `-- presentation/        shared presentation theme/widgets
`-- test/

skills/
|-- conversation/            AI prompt contracts
`-- tech-decision/           architecture decisions

openspec/
|-- specs/                   current behavior contracts
`-- changes/                 active and archived OpenSpec changes
```

Important naming note: the frontend folder is currently spelled
`VFIT_Fontend`. Use that exact path until a deliberate rename is planned.

## Standard Agent Workflow

### 1. Prime And Inspect

Run:

```powershell
bd prime
bd ready
git status --short
```

Then inspect the smallest useful slice of the codebase. Prefer `rg --files` and
`rg` for search. Watch for existing user changes in `git status`; never revert
changes you did not make.

### 2. Choose The Right Planning Mode

Use the lightest workflow that still prevents guessing:

- Tiny documentation or mechanical changes: create/claim a Beads task, inspect
  context, edit, verify, close/update.
- Behavior changes: use OpenSpec or Spec Kit artifacts before code.
- Unclear ideas: explore first, then create an OpenSpec change.
- Bugs or failing tests: use systematic debugging before proposing fixes.
- Multi-step implementation: write a plan before touching code.

### 3. Implement With Project Boundaries

For backend work:

- Add controllers under the owning `modules/*/controller`.
- Keep DTOs under the owning module.
- Keep persistence behind repositories.
- Use services, mappers, events, DTOs, and API envelopes instead of reaching
  across module internals.
- Use Spring events or existing WebSocket/scheduler/webhook patterns for async
  flows. Do not claim RabbitMQ, Kafka, or JMS exists.

For frontend work:

- Keep feature code under `lib/features/<feature>/`.
- Put shared routing, network, theme, widgets, constants, and utilities under
  `lib/core/`.
- Use GoRouter route guards consistently with auth, onboarding, admin, and
  customer flows.
- Use Riverpod for app-level state and BLoC where the feature already uses it.
- Use Dio through the existing network layer and token storage.

### 4. Verify Before Completion

Pick verification by blast radius:

```powershell
# Backend
cd VFIT_Backend
mvn test

# Frontend
cd VFIT_Fontend
flutter test
dart analyze
```

For UI work, also run the app when feasible and inspect the changed screens on
mobile-sized and desktop/web-sized viewports. For AI, payment, auth, or
WebSocket changes, verify both happy path and guarded/fallback path.

### 5. Close And Sync

Before handoff:

```powershell
bd close <id> --reason="Completed"
git status --short
git pull --rebase
git push
git status
```

If code changed, commit and push. If the task is intentionally documentation
only, commit and push the documentation change plus Beads state as the project
workflow requires.

## OpenSpec Workflow For V-FIT

OpenSpec is the preferred behavior-first workflow for feature and architecture
changes. Its principle is brownfield-first: describe what changes in the
existing system instead of pretending the system is greenfield.

Use this flow:

```text
proposal -> delta specs -> design -> tasks -> implementation -> verify -> archive
```

For V-FIT, change folders live in `openspec/changes/<change-name>/` and current
behavior lives in `openspec/specs/`.

### When To Use OpenSpec

Use OpenSpec for:

- New or changed public API behavior.
- Auth, onboarding, subscription, payment, AI, privacy, or admin changes.
- Flutter navigation and user-flow changes.
- Any change that modifies externally visible behavior.
- Multi-module backend changes.
- Changes that need reviewable intent and non-goals.

OpenSpec artifacts should stay behavior-focused:

- `proposal.md`: why this change exists, scope, non-goals.
- `specs/**/spec.md`: ADDED/MODIFIED/REMOVED requirements with scenarios.
- `design.md`: technical approach, data flow, module boundaries, risks.
- `tasks.md`: small, testable implementation steps.

Do not put internal class names in delta specs unless the behavior contract
depends on them. Put implementation details in `design.md` or `tasks.md`.

### V-FIT OpenSpec Domains

Prefer these domain names for new or updated specs:

- `auth`
- `onboarding`
- `ai-coaching`
- `exercise-library`
- `workouts`
- `nutrition`
- `progress`
- `gamification`
- `payment`
- `admin`
- `app-config`
- `mobile-ui`

Each requirement should be testable with Given/When/Then scenarios. Include
guard and fallback scenarios for premium AI, payment, auth, upload, and
malformed AI output.

## Superpowers Workflow For V-FIT

Superpowers contributes execution discipline. Adapt it to this repo as follows.

### Brainstorming

Use when the request is creative, ambiguous, or asks for a new feature. First
inspect the project, then clarify intent, propose two or three approaches, and
only then write a design. For V-FIT, include:

- User flow: onboarding, home, workout, nutrition, progress, profile, admin.
- Backend boundary: module, controller, service, repository, event, WebSocket.
- AI boundary: whether `AiClient` is involved and what contract/fallback is
  required.
- Data boundary: MongoDB document, Redis key, local Flutter storage, DTO.
- Safety boundary: auth, onboarding, premium, rate limits, upload limits.

### Writing Plans

Use for multi-step work. A good V-FIT plan lists exact files, tests, commands,
and expected outcomes. Each task should be small enough to verify independently.
Plan tests before implementation.

### Test-Driven Development

For behavior changes, write the failing test first, verify it fails for the
right reason, then implement minimal code, then verify green.

Backend test targets:

- Service behavior with unit tests.
- DTO validation and mapper behavior where risk exists.
- Security, premium gating, payment, and AI fallback behavior.

Flutter test targets:

- Widget state for loading, empty, error, and success.
- Bloc/Riverpod state transitions.
- Repository parsing and error mapping.
- Route guard behavior when practical.

### Systematic Debugging

For any failure:

1. Read the full error and stack trace.
2. Reproduce with exact commands.
3. Check recent diffs and relevant config.
4. Trace data across boundaries: Flutter -> Dio -> Spring controller ->
   service -> repository or AI/payment client.
5. Compare to a working module.
6. Form one hypothesis and test the smallest change.
7. Add a regression test before fixing when the issue is code behavior.

### Verification Before Completion

Never claim completion from confidence. Claim it only after fresh verification.
If verification cannot run, state why and describe the residual risk.

## Flutter Best Practices For This App

### Architecture

- Keep feature-first structure. Do not move feature code into generic buckets
  unless it is truly shared.
- Preserve the `core/` layer for cross-cutting concerns.
- Keep generated Freezed/JSON files generated, not hand-edited.
- Keep REST parsing and error mapping in repositories/data models, not widgets.
- Keep secure tokens only in `flutter_secure_storage`.
- Use Hive/shared preferences for lightweight cache and preferences only.

### State

- Use Riverpod for global app state, auth coordination, providers, and network
  dependency access.
- Use BLoC in features that already use BLoC, such as admin dashboard,
  auth, nutrition, personalized workout, payment, and exercise library.
- Do not duplicate the same source of truth across Riverpod, BLoC, and widget
  local state.
- Widgets should render state; repositories and controllers should own effects.

### Routing

- Keep auth redirect logic centralized in `lib/core/router/app_router.dart`.
- Admin users should route to `/admin/revenue`.
- Pending onboarding users should route to `/onboarding`.
- Customer protected flows should require authenticated active users.
- New premium routes must align with backend premium gates.

### Networking

- Use existing Dio/network providers and API endpoint constants.
- Map backend `ApiResponse` and error envelopes consistently.
- Handle token refresh and logout signals through the existing auth network
  layer.
- Do not call AI providers directly from Flutter.

### UI Implementation

- Use the existing Material 3 theme and shared widgets before adding new
  primitives.
- Keep layouts responsive for Android, iOS, and Flutter web.
- Every async surface needs loading, empty, error, and success states.
- Camera, image upload, AI, payment, and progress screens need clear fallback
  and permission-denied states.
- Avoid hardcoded production credentials, API URLs, and secrets. Use
  `--dart-define` or backend config.

## Taste Skill UI/UX Rules Adapted To V-FIT

Taste Skill is primarily written for web landing pages and redesigns. V-FIT is
a mobile-first product app, so use the principles, not the web-specific stack
rules.

### Design Read For V-FIT

Read V-FIT screens as:

```text
Mobile-first fitness coaching product for Vietnamese users, with energetic
premium AI coaching, clear habit loops, and admin surfaces that should be
quiet, dense, and operational.
```

Default dials:

- Customer fitness screens: medium variance, low-to-medium motion,
  medium density.
- AI coaching screens: high clarity, low distraction, confidence/fallback
  visible but calm.
- Admin screens: low variance, low motion, higher density.
- Onboarding and payment: trust-first, low ambiguity, restrained motion.

### Anti-Slop Rules

Avoid these generic AI UI patterns:

- Purple/blue glow as the default identity.
- Three identical feature cards when a workflow layout would be clearer.
- Decorative badges and labels that do not carry meaning.
- Huge marketing hero sections inside the app.
- Random gradients, glassmorphism, or heavy shadows.
- Empty screens that simply say "No data".
- Copy such as "Elevate", "Unleash", "Next-Gen", or "Game-changer".

### Minimalist UI Rules

Apply minimalism as product clarity, not emptiness:

- Prefer strong typography, clear hierarchy, generous whitespace, and crisp
  dividers.
- Keep cards for repeated items, framed tools, and modals. Do not nest cards.
- Use one radius system per screen. Current app themes use roughly 14-16px
  cards/inputs and pill chips/buttons; keep that rule or deliberately update it
  across the screen.
- Keep shadows minimal. Use borders, surface contrast, and spacing first.
- Use a small number of accent colors with semantic meaning.
- Use tabular figures for metrics, revenue, streaks, macros, weights, and
  progress data when possible.

### Redesign Existing Screens

When improving an existing V-FIT screen:

1. Audit before editing: route, state manager, dependencies, theme usage, empty
   states, error states, accessibility, and analytics/payment/auth implications.
2. Preserve working information architecture unless the task explicitly asks
   to change it.
3. Preserve existing route names, API endpoint usage, and form field meaning.
4. Modernize in this order: typography, spacing, color calibration,
   interactions, state coverage, then layout recomposition.
5. Work with Flutter and Material 3. Do not introduce a web design system.

### Fitness Product UI Rules

- Coaching copy should be short, specific, and supportive.
- Avoid shame-based language around body metrics, weight, photos, streaks, or
  food.
- AI confidence and fallback should be visible when it changes trust.
- Workout and form-check screens should prioritize safety, current action, and
  one next cue.
- Nutrition screens should frame calories and macros as estimates, especially
  for image-based AI scans.
- Payment screens should be calm, explicit about pending/paid/expired state,
  and never imply VIP is unlocked before backend confirmation.

### Admin UI Rules

- Admin surfaces are operational tools, not marketing pages.
- Prefer compact, scannable layouts with predictable navigation.
- Use charts, tables, filters, and metrics with restrained styling.
- Do not use decorative hero layouts, oversized cards, or motion-heavy effects
  on revenue and user management screens.

## AI Prompt And Contract Rules

Before changing AI behavior:

1. Read `skills/conversation/system.prompt.md`.
2. Identify the flow: body analysis, form check, food estimate, personalized
   workout, progress coaching, or payment explanation.
3. Define input fields, output fields, confidence/fallback semantics, and
   unsafe/out-of-scope behavior.
4. Keep user-facing coaching concise Vietnamese unless the contract requires
   machine-only English codes.
5. Update tests or sample cases for malformed AI output and provider failure.

Backend services must parse AI responses into bounded response contracts before
Flutter displays them. If confidence is low, the UI should present uncertainty
without inventing detail.

## Security And Privacy Checklist

For any touched feature, ask:

- Is the route authenticated?
- Should onboarding be required?
- Should active VIP be required?
- Is Redis rate limiting or locking needed?
- Are uploads size/type-limited?
- Is the output typed before display?
- Is sensitive data minimized before AI use?
- Are payment webhooks signed and idempotent?
- Are admin routes separate from customer routes?
- Are logs useful without leaking secrets or raw sensitive content?

## Quality Gates By Area

Backend:

```powershell
cd VFIT_Backend
mvn test
```

Frontend:

```powershell
cd VFIT_Fontend
flutter test
dart analyze
```

Generated Dart models:

```powershell
cd VFIT_Fontend
dart run build_runner build --delete-conflicting-outputs
```

Docker/runtime smoke:

```powershell
cd VFIT_Backend
docker compose up --build
```

Use targeted tests during iteration, then broader tests before handoff when
the change touches shared contracts, security, AI, payment, routing, or theme.

## Handoff Template

When ending a session, include:

- Beads issue id and status.
- What changed.
- Verification commands and results.
- Any commands not run and why.
- Remaining risks or follow-up Beads issues.
- Git commit and push status.

Do not say work is complete until the required verification and push workflow
has succeeded, or until you explicitly state what blocked it.
