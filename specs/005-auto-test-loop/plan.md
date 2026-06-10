# Implementation Plan: Agentic Self-Healing Test Suite

**Branch**: `005-auto-test-loop` | **Date**: 2026-06-10 | **Spec**: [spec.md](file:///d:/EXE_PRM/specs/005-auto-test-loop/spec.md)

**Input**: Feature specification from `/specs/005-auto-test-loop/spec.md`

## Summary

The self-healing test suite automates the feedback loop between code execution, error detection, and agentic correction. The technical approach involves:
1. Creating a PowerShell runner script (`scripts/run-auto-test-loop.ps1`) that executes backend compilation/tests (`mvn clean compile test`) and frontend compilation/tests (`flutter analyze`, `flutter test`), piping the outputs to a dedicated diagnostics file (`artifacts/test_errors.log`).
2. Integrating a fallback retry counter and git-state manager to safely revert failed fix attempts.
3. Defining clear prompt templates in `skills/conversation/self-healing.md` that instruct the AI on how to parse compiler and test failure logs, locate target files, and apply correct modifications.

## Technical Context

**Language/Version**: Java 17+ (Backend), Dart 3.x / Flutter 3.x (Frontend), PowerShell 7+ (Scripts)

**Primary Dependencies**: Maven, Flutter SDK, JUnit 5, Spring Boot Starter Test, Flutter Test

**Storage**: Local MongoDB/Redis (development instances referenced by backend test profiles)

**Testing**: `mvn test` (Backend), `flutter test` (Frontend)

**Target Platform**: Windows / Dev Environment

**Project Type**: Hybrid (Spring Boot backend + Flutter frontend)

**Performance Goals**: Loop iteration (detect, analyze, attempt fix) completed in under 2 minutes.

**Constraints**: Max retry limit per failure to prevent infinite loop execution; safe git tracking to avoid polluting workspace state with invalid patches.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Validate the active plan against the V-FIT constitution:
- AI-native control plane is explicit for reasoning-driven behavior: **Pass**. The control loop uses agentic reasoning to analyze stack traces and apply fixes.
- Prompt files under `skills/conversation/` own AI behavior: **Pass**. A new prompt file `skills/conversation/self-healing.md` will be created to govern how the agent performs error analysis and fixing.
- AI input and output contracts are bounded and reviewable: **Pass**.
- Backend module boundaries, observability, and error envelopes remain intact: **Pass**. This tool only executes external compilation/testing and does not alter production backend boundaries.
- Premium AI paths enforce onboarding, JWT, subscription gates: **Pass (N/A)**.
- Authentication changes preserve canonical user identity: **Pass (N/A)**.

## Project Structure

### Documentation (this feature)

```text
specs/005-auto-test-loop/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (empty/not applicable for tools)
├── quickstart.md        # Phase 1 output (how to run the loop)
└── tasks.md             # Phase 2 output (checklist of tasks)
```

### Source Code (repository root)

```text
scripts/
└── run-auto-test-loop.ps1     # [NEW] Main PowerShell runner script

skills/
└── conversation/
    └── self-healing.md        # [NEW] AI system prompt instructions for self-healing
```

**Structure Decision**: Since this is a developer utility, the code is localized to a root `scripts/` directory for convenience, and the prompt instructions are put under the standard `skills/conversation/` folder according to prompt governance rules.

## Complexity Tracking

*No violations identified.*

---

## Proposed Changes

### Script Runner Component

#### [NEW] [run-auto-test-loop.ps1](file:///d:/EXE_PRM/scripts/run-auto-test-loop.ps1)
A PowerShell script that:
- Runs static analysis and compilation checks first.
- Executes backend Maven tests (`mvn test`) and frontend tests (`flutter test`).
- Traps the first failure, formats the error log, and writes it to `artifacts/test_errors.log` before exiting with code 1.
- If everything passes, writes a success log and exits with code 0.

### AI Prompt Governance

#### [NEW] [self-healing.md](file:///d:/EXE_PRM/skills/conversation/self-healing.md)
Instructions detailing how the agent should:
- Read `artifacts/test_errors.log`.
- Identify the target file path, error line number, and error message.
- Inspect the file and locate the logical bug.
- Apply a fix using `replace_file_content` or `multi_replace_file_content`.
- Use git stash/checkout to revert a change if the compile state worsens.

---

## Verification Plan

### Automated Tests
- Introduce a mock test in backend and frontend that depends on a toggle variable.
- Trigger `run-auto-test-loop.ps1` and verify it fails, writes the error log correctly, and exits with 1.
- Execute the self-healing loop by having the agent parse the log, toggle the variable, rerun the script, and ensure it passes with exit code 0.

### Manual Verification
- Verify output logs are readable, and the agent successfully halts when the maximum retry count is reached.
