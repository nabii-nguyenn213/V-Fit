# Skill: Self-Healing Test execution

This skill outlines how the Antigravity agent handles compilation and test failures automatically to maintain a working workspace.

## Self-Healing Loop Protocol

When asked to run the self-healing test loop, follow these steps sequentially:

### Step 1: Run the Diagnostics script
Execute the runner script in PowerShell:
```powershell
powershell -File scripts/run-auto-test-loop.ps1
```

- If the command returns **Exit Code 0**, stop. The workspace is fully functional and clean. Report success.
- If the command returns **Exit Code 1**, proceed to **Step 2**.

### Step 2: Read and Analyze the Error Log
Read the generated file: `artifacts/test_errors.log`.

Look for patterns pointing to files and lines:
1. **Maven compile/test errors**:
   - Class name / method name.
   - Stack traces pointing to Java source files: `d:/EXE_PRM/VFIT_Backend/src/.../*.java:line_number`
2. **Flutter analyze/test errors**:
   - File path, line number, column: `lib/.../file.dart:line:col` or `test/.../test.dart:line:col`.
   - The message showing `expected` vs `actual` value or the logical exception.

### Step 3: Apply the Code Correction
- Locate the file identified in the error logs.
- Use `view_file` to inspect the source file around the error line.
- Correct the logic or syntax using `replace_file_content` or `multi_replace_file_content`.
- **Constraint**: Do not delete critical business logic or test assertions merely to make them pass unless the test itself is invalid. Fix the underlying implementation to align with contract specifications.

### Step 4: Retry and Keep Track
- Re-run the diagnostics command:
  ```powershell
  powershell -File scripts/run-auto-test-loop.ps1
  ```
- If it fails with the *same* error message and path, revert the file changes using Git (`git checkout -- <file>`) to avoid compounding errors, and attempt a different fix strategy.
- If the loop continues failing for the same issue after **3 consecutive attempts**, stop, revert the change, and request developer assistance.
- If the loop fails with a *new* error, repeat from **Step 2** (this is progress!).

### Step 5: Completion
Once the script returns Exit Code 0, the self-healing process is complete. Output the list of files fixed and a summary of the corrected issues.
