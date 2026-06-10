# Tasks: Agentic Self-Healing Test Suite

**Input**: Design documents from `/specs/005-auto-test-loop/`

**Prerequisites**: plan.md (required), spec.md (required)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create `scripts/` directory in the repository root if it does not exist
- [x] T002 Initialize the empty shell runner script at `scripts/run-auto-test-loop.ps1`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Define the AI instructions for self-healing in `skills/conversation/self-healing.md`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Self-Healing Test Loop (Priority: P1) 🎯 MVP

**Goal**: Implement the core self-healing test runner script and loop execution.

**Independent Test**: Introduce a deliberate test failure in the codebase. Verify that running `scripts/run-auto-test-loop.ps1` fails, writes the exact error to `artifacts/test_errors.log`, and the agent fixes it automatically when running.

### Implementation for User Story 1

- [x] T004 [US1] Implement backend test execution parser in `scripts/run-auto-test-loop.ps1` to run `mvn test` and capture failures.
- [x] T005 [US1] Implement frontend test execution parser in `scripts/run-auto-test-loop.ps1` to run `flutter test` and capture failures.
- [x] T006 [US1] Implement the console redirection and log writer in `scripts/run-auto-test-loop.ps1` to format errors into `artifacts/test_errors.log`.
- [x] T007 [US1] Implement git state checks in the script to ensure modified files can be safely tracked and stashed/reverted if retries fail.
- [x] T008 [US1] Add dry-run verification tasks in `scripts/run-auto-test-loop.ps1` to ensure exit code 0 is returned on success.

**Checkpoint**: At this point, User Story 1 is fully functional and the core self-healing test loop works.

---

## Phase 4: User Story 2 - Automated Diagnostics & Static Analysis (Priority: P2)

**Goal**: Pre-compile static checks and lint validations.

**Independent Test**: Introduce an unused import or compile error. Verify that the script catches the compile error before executing tests.

### Implementation for User Story 2

- [x] T009 [US2] Add compilation check (`mvn clean compile`) to `scripts/run-auto-test-loop.ps1` before test phase.
- [x] T010 [US2] Add lint and analysis checks (`flutter analyze`) to `scripts/run-auto-test-loop.ps1` before test phase.

**Checkpoint**: Pre-compilation errors are resolved first, leading to a faster feedback loop.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T011 Document how to use the test loop in `specs/005-auto-test-loop/quickstart.md`
- [x] T012 Run final validation check of the complete loop on the workspace

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after US1 is complete
