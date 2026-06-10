# Feature Specification: Agentic Self-Healing Test Suite

**Feature Branch**: `005-auto-test-loop`

**Created**: 2026-06-10

**Status**: Draft

**Input**: User description: "tự động test match giữa AI và app của t nếu sai ở đâu thì dừng lại fix xong quét lại từ đầu để tìm lỗi mới đến khi nào xon thì thôi"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Self-Healing Test Loop (Priority: P1)

As a developer using the Antigravity agent, I want the agent to run the application's test suites (frontend and backend) automatically. If a test fails, the agent must intercept the failure, locate the root cause in the source code, apply a correction, and re-run all tests from the beginning. This process should repeat automatically until all tests pass successfully without requiring manual user intervention.

**Why this priority**: Highly critical for unattended testing and code generation. It eliminates manual compile-fix cycles and ensures the workspace remains in a working state.

**Independent Test**: Introduce a deliberate syntax or logical error in a Flutter or Spring Boot file. Start the self-healing agent loop. Verify that the agent detects the error, fixes the file, restarts the test scan, and eventually exits successfully when all tests pass.

**Acceptance Scenarios**:

1. **Given** the test suite has failing tests, **When** the self-healing script is executed, **Then** the loop must start running the tests, catch the first failure, identify the erroneous file, and stop the test execution immediately to perform the fix.
2. **Given** a fix has been successfully applied to a file, **When** the loop continues, **Then** it must start scanning and testing from the very beginning (re-run all tests) rather than just continuing from the failed test.
3. **Given** the test suite has multiple failures in different files, **When** the loop runs, **Then** it must fix them one by one sequentially, restarting from the beginning after each fix, until 100% of the tests pass.
4. **Given** a test fails and cannot be fixed after a configured maximum number of attempts, **When** the limit is reached, **Then** the loop must stop, revert the last unsuccessful change, and report the issue to the developer to prevent infinite loops.

---

### User Story 2 - Automated Workspace Diagnostics & Scanning (Priority: P2)

As a developer, I want the test runner to not only run unit/integration tests but also scan for compiler errors, lint issues, and static analysis warnings, fixing them automatically before proceeding to run runtime tests.

**Why this priority**: Pre-compilation and static analysis checks are much faster than running the full test suite and catch simple errors early.

**Independent Test**: Add an unused import or an invalid Dart/Java syntax. Verify the loop runs static analysis first, fixes the compilation/syntax issues, and then proceeds to tests.

**Acceptance Scenarios**:

1. **Given** a syntax or compilation error in the codebase, **When** the diagnostics tool runs, **Then** it must resolve the compilation error first before attempting to execute runtime tests.

---

### Edge Cases

- **Infinite Loop Protection**: If the agent makes a change that breaks another test, or keeps repeating the same incorrect fix, the system must detect this cycle and halt after a set limit (e.g., 3-5 retries for the same error).
- **Destructive Fixes**: The agent might delete code to make a test pass. Fixes must be validated against compile gates and contract integrity.
- **Port Conflict during Backend Tests**: Spring Boot integration tests require ports. If ports are blocked, tests will fail falsely. The test runner must isolate or handle port conflicts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST support a command-line script (`run-auto-test-loop.ps1` or similar) to start the self-healing cycle.
- **FR-002**: The loop MUST check compiler status first (e.g., `flutter analyze` for frontend, `mvn clean compile` or Gradle compile for backend).
- **FR-003**: The test runner MUST parse compiler/test outputs to extract:
  - The failed test case name.
  - The stack trace or error message.
  - The file path and line number of the failure.
- **FR-004**: Upon detecting a failure, the script MUST request the AI model to analyze the error log and the source file, edit the source code, and save the changes.
- **FR-005**: After applying a code fix, the script MUST restart the execution loop from the compiler check phase.
- **FR-006**: The system MUST maintain a history/log of applied changes so it can revert to the last stable state if the loop gets stuck.
- **FR-007**: The system MUST exit with code 0 once all checks and tests pass, or with code 1 if the retry limit is exceeded.

### Key Entities

- **Test Suite**: A collection of automated tests (unit, integration, or UI tests) for `VFIT_Fontend` and `VFIT_Backend`.
- **Diagnostics Log**: The console output from compiling and running tests, parsed by the agent to find errors.
- **Fix Candidate**: A patch or set of changes proposed by the AI to resolve a specific diagnostics failure.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The self-healing loop successfully resolves simple compilation and unit test errors in under 5 minutes without human intervention.
- **SC-002**: The loop correctly stops and exits with an error status if a test is structurally unfixable (preventing infinite loops).
- **SC-003**: The codebase achieves 100% successful compile rate and passes all defined test cases upon loop completion.

## Assumptions

- The project uses standard testing frameworks: JUnit/Spring Boot Test for `VFIT_Backend` and Flutter Test/Integration Test for `VFIT_Fontend`.
- The Antigravity agent has terminal and file read/write permissions enabled (e.g., via the configuration settings we updated earlier).
- The host machine has all required SDKs (Java, Flutter/Dart, Gradle) pre-configured and accessible via the terminal.
