# Feature Specification: Documentation Consolidation & Config Verification

**Feature Branch**: `008-doc-cleanup`

**Created**: 2026-06-15

**Status**: Draft

**Input**: User description: "scan dự án xóa bớt các file document ddeer clean code tập trung hết các phần mục của dự án vào 1 file readme và đồng thời trong lúc scan thì check xem cái nào đang bị lệch để t đưa lên server và app"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consolidate Project Documentation into Main README.md (Priority: P1)

The developer wants a clean and singular source of truth for project information. All redundant, outdated, or scattered documentation files (such as `CLAUDE.md`, `FEATURES.md`, `REALTIME_AI_INTEGRATION.md`, or generic guides) should be consolidated into the main project `README.md` at the root directory, and redundant documents should be deleted.

**Why this priority**: Crucial for codebase cleanliness and ease of onboarding. Developers should not have to parse multiple files to understand how to run and deploy the project.

**Independent Test**:
- Running `git status` shows deleted redundant documentation files.
- Root `README.md` contains comprehensive sections covering architecture, local startup, endpoints, and deployment rules.

**Acceptance Scenarios**:

1. **Given** scattered files `CLAUDE.md`, `FEATURES.md`, `REALTIME_AI_INTEGRATION.md` exist in the root, **When** the cleanup is executed, **Then** all their unique contents are merged into `README.md` and the original scattered files are deleted.

---

### User Story 2 - Verify Configurations for Backend Server and App Deployment (Priority: P1)

Identify any mismatches in endpoints, ports, host URLs, and configuration modes between the Spring Boot backend (`VFIT_Backend`), FastAPI Recommendation System (`AI-VFIT`), and Flutter App (`VFIT_Fontend`) configurations.

**Why this priority**: Essential to avoid connectivity and runtime errors during production deployment on VPS/Server and production builds of the app.

**Independent Test**:
- A comprehensive audit section is added to `README.md` or a checklist is generated highlighting any configuration mismatches.
- Any conflicting environment parameters are corrected or explicitly documented.

**Acceptance Scenarios**:

1. **Given** the local and production configurations for Flutter, Spring Boot, and FastAPI, **When** configuration verification is executed, **Then** any port/host discrepancies (such as port 5000 vs 8000 for AI components) are identified and recorded.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST consolidate root documentation files (`CLAUDE.md`, `FEATURES.md`, `REALTIME_AI_INTEGRATION.md`) into a structured root `README.md`.
- **FR-002**: Redundant files (`CLAUDE.md`, `FEATURES.md`, `REALTIME_AI_INTEGRATION.md`) MUST be removed to maintain a clean workspace.
- **FR-003**: The consolidated `README.md` MUST preserve crucial operating details like build commands, WebSocket endpoints, ports, and Docker Compose structure.
- **FR-004**: System MUST check for discrepancies in configuration variables (e.g. `AI_BASE_URL` on port 5000 vs `aiBaseUrl` on port 8000) and summarize them clearly in `README.md`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Number of root documentation files reduced from 5 to 2 (`README.md` and `AGENTS.md`).
- **SC-002**: No dead or conflicting API URLs remaining unflagged in the configuration files.
