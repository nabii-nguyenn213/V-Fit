# Implementation Plan: Documentation Consolidation & Config Verification

**Branch**: `007-connect-ai-web2api` | **Date**: 2026-06-15 | **Spec**: [spec.md](file:///d:/EXE_PRM/specs/008-doc-cleanup/spec.md)

## Summary

Consolidate all project-level documentation files (`CLAUDE.md`, `FEATURES.md`, `REALTIME_AI_INTEGRATION.md`, and `docs/AI_AGENT_GUIDE.md`) into a single, comprehensive root `README.md`. Remove the redundant files to clean up the codebase. At the same time, perform a configuration audit to identify and correct any endpoint, port, or host discrepancies across the V-FIT mobile app, Spring Boot backend, and AI modules.

## User Review Required

> [!IMPORTANT]
> - `CLAUDE.md`, `FEATURES.md`, and `REALTIME_AI_INTEGRATION.md` will be deleted from the root directory after their contents are consolidated into the root `README.md`.
> - `docs/AI_AGENT_GUIDE.md` will also be deleted, and its key principles and folder map will be consolidated into the root `README.md`.
> - The port configuration mismatch for AI services (Port 8000 for FastAPI RecommendationSystem vs Port 5000 for Flask api_server.py) is intentional and will be explicitly documented to avoid confusion during deployment.

## Open Questions

None at this stage. All requirements are clear.

## Proposed Changes

### Root Documentation

#### [MODIFY] [README.md](file:///d:/EXE_PRM/README.md)
Consolidate all instructions from other documents, including:
- Beads Issue Tracker rules & Session completion commands (from `CLAUDE.md`)
- V-FIT feature lists and tech stack (from `FEATURES.md`)
- Real-time video stream WebSocket architecture and setup (from `REALTIME_AI_INTEGRATION.md`)
- Key principles, folder map, and security checklist (from `docs/AI_AGENT_GUIDE.md`)
- Configuration discrepancy audit details.

#### [DELETE] [CLAUDE.md](file:///d:/EXE_PRM/CLAUDE.md)
Remove as its content is merged into `README.md`.

#### [DELETE] [FEATURES.md](file:///d:/EXE_PRM/FEATURES.md)
Remove as its content is merged into `README.md`.

#### [DELETE] [REALTIME_AI_INTEGRATION.md](file:///d:/EXE_PRM/REALTIME_AI_INTEGRATION.md)
Remove as its content is merged into `README.md`.

#### [DELETE] [AI_AGENT_GUIDE.md](file:///d:/EXE_PRM/docs/AI_AGENT_GUIDE.md)
Remove as its content is merged into `README.md`.

---

## Verification Plan

### Automated Tests
- Run `git status` to verify that the deleted files are staged for deletion.
- Verify markdown rendering of the consolidated `README.md` to ensure all links and structures are clean and correct.

### Manual Verification
- Review the new `README.md` file sections to ensure no unique or important operational information was lost.
- Confirm all port numbers and service configuration mappings are accurately documented.
