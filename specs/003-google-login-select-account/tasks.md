# Tasks: Google Login Force Account Selection

**Input**: Design documents from `/specs/003-google-login-select-account/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Tests are not explicitly requested in the feature specification, so no automated integration tests are generated. Verification will be handled manually via quickstart.md guidelines.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Mobile frontend: `VFIT_Fontend/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project structure per implementation plan

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Verify local Git and branch state
- [x] T003 [P] Verify google_sign_in package dependency in VFIT_Fontend/pubspec.yaml

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Force Google Account Selection (Priority: P1) 🎯 MVP

**Goal**: Ensure the native Google Sign-in account chooser is displayed on every login click.

**Independent Test**: Perform manual verification per quickstart.md: trigger Google Sign-In, log out, and trigger it again; verify that the account chooser is displayed each time.

### Implementation for User Story 1

- [x] T004 [US1] Call signOut on _googleSignIn in VFIT_Fontend/lib/features/auth/data/services/social_login_client.dart before signIn
- [x] T005 [US1] Add try-catch block around pre-signin signOut call to handle errors gracefully

**Checkpoint**: User Story 1 is now fully implemented and testable.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T006 [P] Verify with manual test sequence in quickstart.md
- [x] T007 [P] Verify application compiles and has no linting errors

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
- **Polish (Final Phase)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)

### Parallel Opportunities

- T003 can be run in parallel with T002.
- T006 and T007 can be run in parallel.
