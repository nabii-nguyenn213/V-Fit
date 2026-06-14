# Tasks: Documentation Consolidation & Config Verification

**Input**: Design documents from `/specs/008-doc-cleanup/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Initialize the active feature branch and spec files under specs/008-doc-cleanup/

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core checks and setups before merging and cleaning up

- [x] T002 Verify that current documentation files (README.md, CLAUDE.md, FEATURES.md, REALTIME_AI_INTEGRATION.md, docs/AI_AGENT_GUIDE.md) exist and are readable

## Phase 3: User Story 1 - Consolidate Project Documentation into Main README.md (Priority: P1)

**Goal**: Merge all scattered documentation files into root README.md and delete the redundant source files.

**Independent Test**: Root README.md contains sections from all source files and the source files are deleted from the repo.

### Implementation for User Story 1

- [x] T003 [US1] Extract unique sections (Beads commands, build/test details) from CLAUDE.md and append/merge them into README.md
- [x] T004 [US1] Extract V-FIT feature lists and tech stack from FEATURES.md and append/merge them into README.md
- [x] T005 [US1] Extract WebSockets architecture, setup instructions, and testing flows from REALTIME_AI_INTEGRATION.md and append/merge them into README.md
- [x] T006 [US1] Extract folder map, core principles, and agent workflow details from docs/AI_AGENT_GUIDE.md and append/merge them into README.md
- [x] T007 [US1] Clean up formatting and cross-references within the consolidated README.md
- [x] T008 [US1] Delete source documentation files CLAUDE.md, FEATURES.md, REALTIME_AI_INTEGRATION.md, and docs/AI_AGENT_GUIDE.md

## Phase 4: User Story 2 - Verify Configurations for Backend Server and App Deployment (Priority: P1)

**Goal**: Audit and reconcile server/app configurations and document discrepancies in README.md.

**Independent Test**: A "Configuration Verification & Discrepancies" section is added to README.md detailing port/host configurations.

### Implementation for User Story 2

- [x] T009 [US2] Check and document the difference between Port 8000 (FastAPI RecommendationSystem) and Port 5000 (Flask api_server.py) in README.md
- [x] T010 [US2] Verify dynamic WebSocket URL construction using WebSocketUrlBuilder in VFIT_Fontend/lib/core/network/web_socket_url_builder.dart
- [x] T011 [US2] Audit all backend application.properties, Docker Compose configurations, and Flutter environment.dart targets to ensure URLs align
- [x] T012 [US2] Write the final configuration alignment matrix into the consolidated README.md

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T013 Verify that git status matches target deletions and modifications
- [x] T014 Run quickstart.md validation by reading consolidated README.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
- **Polish (Final Phase)**: Depends on all desired user stories being complete
