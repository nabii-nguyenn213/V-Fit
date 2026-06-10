# PowerShell Script to run Auto-Test-Loop and capture compiler/test errors for self-healing AI.
param (
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [int]$MaxRetries = 5
)

# Ensure artifacts directory exists
$ArtifactsDir = Join-Path $PSScriptRoot "../artifacts"
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null
}

$ErrorLogPath = Join-Path $ArtifactsDir "test_errors.log"
if (Test-Path $ErrorLogPath) {
    Remove-Item $ErrorLogPath -Force
}

function Log-Error($message) {
    Write-Host " [ERROR] $message" -ForegroundColor Red
    Add-Content -Path $ErrorLogPath -Value $message
}

function Log-Info($message) {
    Write-Host " [INFO] $message" -ForegroundColor Green
}

Log-Info "Starting Auto-Test-Loop..."

# Git tracking status
Log-Info "Checking workspace git status..."
$GitStatus = git status --porcelain
if ($GitStatus) {
    Log-Info "Modified files detected before testing:"
    Write-Host $GitStatus -ForegroundColor Yellow
}

$BackendPath = Resolve-Path (Join-Path $PSScriptRoot "../VFIT_Backend")
$FrontendPath = Resolve-Path (Join-Path $PSScriptRoot "../VFIT_Fontend")

$RunBackend = $true
$RunFrontend = $true

if ($BackendOnly) {
    $RunFrontend = $false
}
if ($FrontendOnly) {
    $RunBackend = $false
}

# --- BACKEND CHECKS ---
if ($RunBackend -and (Test-Path $BackendPath)) {
    Log-Info "--- Executing Backend Compilation & Tests ---"
    
    # 1. Compilation
    Log-Info "Compiling VFIT_Backend..."
    Push-Location $BackendPath
    cmd.exe /c "mvn clean compile -DskipTests 2>&1" | Out-File -FilePath "$ArtifactsDir/mvn_compile.log" -Encoding utf8
    $ExitCode = $LASTEXITCODE
    Pop-Location

    if ($ExitCode -ne 0) {
        Log-Error "Backend compilation failed. Parsing errors..."
        $CompileLog = Get-Content "$ArtifactsDir/mvn_compile.log"
        $ErrorLines = $CompileLog | Where-Object { $_ -like "*[ERROR]*" }
        foreach ($line in $ErrorLines) {
            Log-Error $line
        }
        exit 1
    }
    Log-Info "Backend compilation successful."

    # 2. Runtime Tests
    Log-Info "Running Backend Tests..."
    Push-Location $BackendPath
    cmd.exe /c "mvn test 2>&1" | Out-File -FilePath "$ArtifactsDir/mvn_test.log" -Encoding utf8
    $ExitCode = $LASTEXITCODE
    Pop-Location
    
    if ($ExitCode -ne 0) {
        $TestLog = Get-Content "$ArtifactsDir/mvn_test.log"
        
        # Verify if there is an actual test failure or if it's just JVM warnings/errors
        $HasFailures = $TestLog | Where-Object { $_ -like "*Failed tests:*" -or $_ -like "*Tests run: *, Failures: *, Errors: *, Skipped: *" }
        if ($HasFailures) {
            Log-Error "Backend tests failed. Parsing errors..."
            $FailureIndex = [array]::IndexOf($TestLog, ($TestLog | Where-Object { $_ -like "*Failed tests:*" } | Select-Object -First 1))
            if ($FailureIndex -ge 0) {
                for ($i = $FailureIndex; $i -lt [Math]::Min($FailureIndex + 20, $TestLog.Count); $i++) {
                    Log-Error $TestLog[$i]
                }
            } else {
                # Dump summary lines
                $SummaryLines = $TestLog | Where-Object { $_ -like "*Tests run: *, Failures: *, Errors: *, Skipped: *" }
                foreach ($line in $SummaryLines) {
                    Log-Error $line
                }
            }
            exit 1
        } else {
            # Check if there is a compilation error in tests
            $HasCompFailures = $TestLog | Where-Object { $_ -like "*[ERROR]*" }
            if ($HasCompFailures) {
                Log-Error "Backend test compilation failed. Parsing errors..."
                foreach ($line in ($TestLog | Where-Object { $_ -like "*[ERROR]*" })) {
                    Log-Error $line
                }
                exit 1
            }
            Log-Info "Backend tests executed successfully with warnings (Exit code was non-zero but no test failures found)."
        }
    } else {
        Log-Info "Backend tests passed successfully."
    }
}

# --- FRONTEND CHECKS ---
if ($RunFrontend -and (Test-Path $FrontendPath)) {
    Log-Info "--- Executing Frontend Compilation & Tests ---"
    
    # 1. Static Analysis (linting/compilation)
    Log-Info "Analyzing VFIT_Fontend..."
    Push-Location $FrontendPath
    cmd.exe /c "flutter analyze 2>&1" | Out-File -FilePath "$ArtifactsDir/flutter_analyze.log" -Encoding utf8
    $ExitCode = $LASTEXITCODE
    Pop-Location

    if ($ExitCode -ne 0) {
        $AnalyzeLog = Get-Content "$ArtifactsDir/flutter_analyze.log"
        # Only fail if there are lines matching "error •"
        $ErrorLines = $AnalyzeLog | Where-Object { $_ -match "error •" }
        if ($ErrorLines) {
            Log-Error "Frontend static analysis failed (actual errors found). Parsing errors..."
            foreach ($line in $ErrorLines) {
                Log-Error $line
            }
            exit 1
        } else {
            Log-Info "Frontend analysis has warning/info lines but no hard compilation errors. Proceeding..."
        }
    } else {
        Log-Info "Frontend analysis successful."
    }

    # 2. Runtime Tests
    Log-Info "Running Frontend Tests..."
    Push-Location $FrontendPath
    cmd.exe /c "flutter test 2>&1" | Out-File -FilePath "$ArtifactsDir/flutter_test.log" -Encoding utf8
    $ExitCode = $LASTEXITCODE
    Pop-Location
    
    if ($ExitCode -ne 0) {
        Log-Error "Frontend tests failed. Parsing errors..."
        $TestLog = Get-Content "$ArtifactsDir/flutter_test.log"
        $ErrorLines = $TestLog | Where-Object { $_ -match "expected:|actual:|at\s+|\[FAIL\]|file:\/\/\/" }
        foreach ($line in $ErrorLines) {
            Log-Error $line
        }
        # Dump failure summary
        $StartLine = [Math]::Max(0, $TestLog.Count - 25)
        for ($i = $StartLine; $i -lt $TestLog.Count; $i++) {
            Log-Error $TestLog[$i]
        }
        exit 1
    }
    Log-Info "Frontend tests passed successfully."
}

Log-Info "All selected compilations and test suites passed successfully!"
exit 0
