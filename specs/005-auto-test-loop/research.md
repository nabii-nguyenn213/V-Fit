# Research: Agentic Self-Healing Test Suite

## Decision 1: Command Line Test Execution and Output Capture
- **Chosen Option**: Standard stdout redirection and grep filtering in PowerShell.
- **Rationale**: 
  - Maven (`mvn test`) and Flutter (`flutter test`) write test failures directly to stdout/stderr.
  - Writing a wrapper PowerShell script allows us to capture stdout, identify failure lines (e.g., lines containing `[ERROR]` in Maven or `[FAIL]` in Flutter), and dump a concise snippet to `artifacts/test_errors.log`.
  - This avoids parsing complex XML or JSON test reports, keeping the input token size small and easy for the AI model to parse.
- **Alternatives Considered**:
  - *Surefire XML Parsing*: Parsing Surefire XML reports (`target/surefire-reports/*.xml`). Rejected because it requires additional XML parsers in PowerShell, which is verbose and slow.
  - *Flutter JSON Reporter*: Running `flutter test --machine`. Rejected because the output format is verbose JSON stream, harder for a regex or AI to quickly pinpoint without extra processing.

## Decision 2: Git State Management for Revert Safeguards
- **Chosen Option**: Tracking modified files using `git status --porcelain` and using `git checkout -- <file>` to revert.
- **Rationale**:
  - When the AI attempts to fix a test, it might introduce compiling errors or break other existing tests.
  - Having a snapshot of files modified during the loop allows us to revert a file to its state before the AI edited it.
  - The script will log files changed in each iteration. If an iteration fails to compile or resolve the target error, it runs `git checkout -- <modified_file>` to undo the last change before retrying or giving up.
- **Alternatives Considered**:
  - *Git Stash*: Stashing changes. Rejected because it stashes the entire workspace, whereas we might want to keep some successful edits while reverting only the latest failing one.
  - *Manual backup files (`.bak`)*: Creating backup copies of files. Rejected because Git is already initialized in this repository and is the standard way to track changes.

## Decision 3: Diagnostics Parsing Patterns
- **Chosen Option**: RegExp matching for error files and lines:
  - Backend Java Compile errors: `\[ERROR\]\s+(.*?):\[(\d+),(\d+)\]\s+(.*)`
  - Backend Test failures: Standard stack traces with file references: `at (.*?)\((.*?)\.java:(\d+)\)`
  - Frontend Dart Analyze errors: `([a-zA-Z0-9_\-\.\/]+):(\d+):(\d+)`
  - Frontend Test failures: `\s+file:\/\/\/(.*?):(\d+):(\d+)`
- **Rationale**: Extremely robust and fast pattern matching to guide the AI to the exact file and line number.
