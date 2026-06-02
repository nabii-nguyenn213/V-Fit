---
description: "Implementation tasks for AI-Native V-FIT Baseline"
---

# Tasks: AI-Native V-FIT Baseline

**Input**: Design documents from `specs/001-ai-native-baseline/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`,
`contracts/ai-contracts.md`, `quickstart.md`

**Tests**: Test tasks are not generated because the feature specification does
not request TDD or mandatory new tests. Quality gates remain Maven tests for the
backend and Flutter widget/unit tests for affected frontend changes.

**Organization**: Tasks are grouped by user story to preserve independent
implementation and verification.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel because it touches different files or has no
  dependency on incomplete work.
- **[Story]**: User story label from `spec.md`.
- Every task includes an exact file path.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the baseline documentation and local verification surface.

- [ ] T001 Verify backend build and test command in `D:\EXE_PRM\specs\001-ai-native-baseline\quickstart.md`
- [ ] T002 Verify Flutter run command and required dart defines in `D:\EXE_PRM\specs\001-ai-native-baseline\quickstart.md`
- [ ] T003 [P] Confirm source tree paths in `D:\EXE_PRM\specs\001-ai-native-baseline\plan.md`
- [ ] T004 [P] Confirm prompt governance paths in `D:\EXE_PRM\skills\conversation\system.prompt.md`
- [ ] T005 [P] Confirm architecture decision path in `D:\EXE_PRM\skills\tech-decision\decision.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared contracts and boundaries that MUST be correct before any
user story is finalized.

- [ ] T006 Review API envelope consistency in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\common`
- [ ] T007 [P] Review JWT and security filter baseline in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\security`
- [ ] T008 [P] Review MongoDB and Redis infrastructure wiring in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\infrastructure`
- [ ] T009 [P] Review frontend network client and token storage baseline in `D:\EXE_PRM\VFIT_Fontend\lib\core`
- [ ] T010 Update baseline entity mapping if needed in `D:\EXE_PRM\specs\001-ai-native-baseline\data-model.md`
- [ ] T011 Validate AI input/output boundaries, premium gates, rate limits, and fallback behavior in `D:\EXE_PRM\specs\001-ai-native-baseline\contracts\ai-contracts.md`
- [ ] T012 Validate authentication provider boundaries for affected auth flows in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\auth`

**Checkpoint**: Foundation ready; user story work can proceed independently.

---

## Phase 3: User Story 1 - Complete Fitness Onboarding (Priority: P1)

**Goal**: A new user registers, verifies OTP, completes onboarding, and reaches
the main app with an active profile.

**Independent Test**: Register, verify OTP, submit onboarding metrics, upload
body scan, and confirm `/home` becomes available.

### Implementation for User Story 1

- [ ] T013 [P] [US1] Review registration, OTP, login, refresh, logout, forgot password, and reset password endpoints in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\auth`
- [ ] T014 [P] [US1] Review user profile and onboarding state model in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\user`
- [ ] T015 [US1] Verify protected-route onboarding guard behavior in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\security`
- [ ] T016 [P] [US1] Review Flutter register, OTP, login, and password recovery screens in `D:\EXE_PRM\VFIT_Fontend\lib\features\auth`
- [ ] T017 [P] [US1] Review Flutter onboarding flow and route redirects in `D:\EXE_PRM\VFIT_Fontend\lib`
- [ ] T018 [US1] Document onboarding verification results in `D:\EXE_PRM\specs\001-ai-native-baseline\quickstart.md`

**Checkpoint**: US1 is independently verifiable through registration,
onboarding completion, and `/home` access.

---

## Phase 4: User Story 2 - Consume AI Premium Coaching (Priority: P1)

**Goal**: A premium user receives typed, rate-limited, fallback-safe AI food,
form check, body analysis, and workout guidance.

**Independent Test**: Activate VIP, call an AI endpoint, and verify typed,
rate-limited, fallback-safe output.

### Implementation for User Story 2

- [ ] T019 [P] [US2] Review AI client boundary and fallback behavior in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\ai`
- [ ] T020 [P] [US2] Review premium feature gates and subscription checks in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\subscription`
- [ ] T021 [P] [US2] Review AI rate limiting and circuit breaker configuration in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\infrastructure`
- [ ] T022 [US2] Align food calorie estimate contract with implementation in `D:\EXE_PRM\specs\001-ai-native-baseline\contracts\ai-contracts.md`
- [ ] T023 [US2] Align form-check WebSocket contract with implementation in `D:\EXE_PRM\specs\001-ai-native-baseline\contracts\ai-contracts.md`
- [ ] T024 [US2] Align body analysis contract with implementation in `D:\EXE_PRM\specs\001-ai-native-baseline\contracts\ai-contracts.md`
- [ ] T025 [P] [US2] Review Flutter AI form-check page and state handling in `D:\EXE_PRM\VFIT_Fontend\lib\features`
- [ ] T026 [P] [US2] Review nutrition AI food scan UI and BLoC wiring in `D:\EXE_PRM\VFIT_Fontend\lib\features\nutrition`
- [ ] T027 [US2] Document AI premium verification results in `D:\EXE_PRM\specs\001-ai-native-baseline\quickstart.md`

**Checkpoint**: US2 returns bounded success or fallback contracts for premium AI
flows and blocks free-tier access.

---

## Phase 5: User Story 3 - Train With Catalogs And Progress (Priority: P2)

**Goal**: A user can browse training and nutrition catalogs, store progress,
join challenges, and see habit-loop state.

**Independent Test**: Browse catalog screens, create progress snapshots, join
challenges, and verify progress remains visible.

### Implementation for User Story 3

- [ ] T028 [P] [US3] Review workout catalog endpoints and models in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\exercise`
- [ ] T029 [P] [US3] Review exercise library endpoints and seed data in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\exercise_library`
- [ ] T030 [P] [US3] Review nutrition catalog endpoints in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\nutrition`
- [ ] T031 [P] [US3] Review progress journey snap APIs in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\progress`
- [ ] T032 [P] [US3] Review gamification challenge and badge APIs in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\gamification`
- [ ] T033 [P] [US3] Review personalized workout state and goal metadata in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\personalized_workout`
- [ ] T034 [P] [US3] Review Flutter workout, exercise library, nutrition, progress, and gamification screens in `D:\EXE_PRM\VFIT_Fontend\lib\features`
- [ ] T035 [US3] Update catalog and progress entity notes in `D:\EXE_PRM\specs\001-ai-native-baseline\data-model.md`

**Checkpoint**: US3 is independently verifiable through browsing, progress
photo storage, and challenge participation.

---

## Phase 6: User Story 4 - Unlock Premium By Payment (Priority: P2)

**Goal**: A user can apply vouchers, pay through Sepay/VietQR, and receive VIP
status.

**Independent Test**: Apply voucher, create payment, simulate webhook, and
verify subscription snapshot becomes active.

### Implementation for User Story 4

- [ ] T036 [P] [US4] Review voucher validation and one-voucher-per-order behavior in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\payment`
- [ ] T037 [P] [US4] Review Sepay webhook verification and idempotency in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\payment`
- [ ] T038 [P] [US4] Review VIP subscription snapshot update behavior in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\subscription`
- [ ] T039 [P] [US4] Review Flutter premium checkout, payment status, and voucher state in `D:\EXE_PRM\VFIT_Fontend\lib\features`
- [ ] T040 [US4] Document payment and premium unlock verification results in `D:\EXE_PRM\specs\001-ai-native-baseline\quickstart.md`

**Checkpoint**: US4 is independently verifiable from voucher application through
VIP unlock.

---

## Phase 7: User Story 5 - Admin Operates The Platform (Priority: P3)

**Goal**: Admin users manage platform state and revenue without entering
customer flows.

**Independent Test**: Login as admin and confirm redirect to `/admin/revenue`.

### Implementation for User Story 5

- [ ] T041 [P] [US5] Review admin dashboard and revenue APIs in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\app`
- [ ] T042 [P] [US5] Review admin user management APIs in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\user`
- [ ] T043 [P] [US5] Review admin app configuration APIs in `D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\app`
- [ ] T044 [P] [US5] Review Flutter admin revenue, user management, and app config routes in `D:\EXE_PRM\VFIT_Fontend\lib`
- [ ] T045 [US5] Verify admin and non-admin route guard behavior in `D:\EXE_PRM\VFIT_Fontend\lib`

**Checkpoint**: US5 is independently verifiable through admin login and route
guard behavior.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency, quality gates, and handoff.

- [ ] T046 [P] Reconcile functional requirement coverage in `D:\EXE_PRM\specs\001-ai-native-baseline\spec.md`
- [ ] T047 [P] Reconcile constitution check status in `D:\EXE_PRM\specs\001-ai-native-baseline\plan.md`
- [ ] T048 [P] Reconcile baseline checklist results in `D:\EXE_PRM\specs\001-ai-native-baseline\checklists\requirements.md`
- [ ] T049 Run backend quality gate from `D:\EXE_PRM\VFIT_Backend\pom.xml`
- [ ] T050 Run Flutter quality gate from `D:\EXE_PRM\VFIT_Fontend\pubspec.yaml`
- [ ] T051 Record final baseline verification notes in `D:\EXE_PRM\specs\001-ai-native-baseline\quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **US1 and US2 (P1)**: Depend on Foundational; can proceed in parallel after
  shared security/network boundaries are understood.
- **US3 and US4 (P2)**: Depend on Foundational; US4 also validates subscription
  state used by US2 premium gates.
- **US5 (P3)**: Depends on Foundational and can proceed after auth role behavior
  is confirmed.
- **Polish (Phase 8)**: Depends on all selected user stories.

### User Story Dependencies

- **US1**: Independent MVP for identity and onboarding.
- **US2**: Independent once VIP state can be seeded or activated.
- **US3**: Independent daily habit loop.
- **US4**: Independent payment-to-subscription flow; supports US2 validation.
- **US5**: Independent admin operations flow after role-based auth is verified.

### Parallel Opportunities

- T003, T004, and T005 can run in parallel.
- T007, T008, and T009 can run in parallel.
- US1 backend review tasks T013 and T014 can run alongside frontend tasks T016
  and T017.
- US2 contract alignment tasks T022, T023, and T024 can run after T019.
- US3 module reviews T028 through T034 can run in parallel.
- US4 backend and frontend reviews T036 through T039 can run in parallel.
- US5 admin reviews T041 through T044 can run in parallel.

---

## Parallel Example: User Story 2

```powershell
# Parallel work items after foundational checks:
Task: "Review AI client boundary and fallback behavior in D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\ai"
Task: "Review premium feature gates and subscription checks in D:\EXE_PRM\VFIT_Backend\src\main\java\com\vfit\modules\subscription"
Task: "Review nutrition AI food scan UI and BLoC wiring in D:\EXE_PRM\VFIT_Fontend\lib\features\nutrition"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete US1 to prove identity, onboarding, and protected app entry.
3. Complete US2 to prove the paid AI value path.
4. Stop and validate both P1 stories through `quickstart.md`.

### Incremental Delivery

1. Deliver US1 as the identity/onboarding foundation.
2. Deliver US2 as premium AI coaching.
3. Deliver US3 as daily catalog/progress habit loop.
4. Deliver US4 as payment-to-VIP unlock.
5. Deliver US5 as admin operations.
6. Complete polish and quality gates.

### Quality Gates

- Backend: run Maven tests from `D:\EXE_PRM\VFIT_Backend\pom.xml`.
- Frontend: run Flutter analysis/tests from `D:\EXE_PRM\VFIT_Fontend\pubspec.yaml`.
- Documentation: verify `spec.md`, `plan.md`, `data-model.md`,
  `contracts/ai-contracts.md`, and `quickstart.md` remain consistent.
