# Quickstart Guide: Agentic Self-Healing Test Suite

This guide outlines how to execute the auto-test-loop and let the agent fix errors automatically.

## Prerequisites

1. Ensure the Antigravity agent has **Terminal Commands** and **File Read/Write** permissions set to **Always Allow** in the extension settings:
   - `command(*)` -> Allowed
   - `write_file(*)` -> Allowed
   - `read_file(*)` -> Allowed

2. Ensure Java/Maven and Flutter/Dart are installed and available in the environment path.

## How to Trigger the Self-Healing Loop

Simply ask the Antigravity agent in the chat to run the self-healing test loop:

```text
Chạy self-healing test loop và tự sửa các lỗi test/biên dịch nếu có.
```

The agent will execute:
1. The PowerShell test script:
   ```powershell
   powershell -File scripts/run-auto-test-loop.ps1
   ```
2. If the script exits with code `0`, the loop finishes and reports success.
3. If the script exits with code `1`, the agent will:
   - Read the error log at `artifacts/test_errors.log`.
   - Locate the target file and line.
   - Edit the code to fix the issue.
   - Restart the loop by executing the script again.

## Manual Testing
You can manually run the script from the root workspace directory using:
```powershell
powershell -File scripts/run-auto-test-loop.ps1
```
This will print any failures to the console and output `artifacts/test_errors.log` for you or the AI to inspect.
