# ============================================================================
# ScanDoc - Crash Log Capture Script (PowerShell)
# ============================================================================

function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "============================================================================"
Write-Info "  ScanDoc - Crash Log Capture"
Write-Info "============================================================================"
Write-Host ""

# Find ADB
$adbPath = $null
$androidHome = $env:ANDROID_HOME
if (-not $androidHome) {
    $androidHome = "$env:LOCALAPPDATA\Android\Sdk"
}

$adbPath = "$androidHome\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Error "ADB not found at: $adbPath"
    Write-Warning "Please ensure Android SDK is installed"
    exit 1
}

Write-Success "Using ADB: $adbPath"
Write-Host ""

# Check device connection
Write-Info "Checking device connection..."
& $adbPath devices
Write-Host ""

# Clear old logs
Write-Info "Clearing old logs..."
& $adbPath logcat -c
Write-Host ""

Write-Info "============================================================================"
Write-Info "  Instructions:"
Write-Info "============================================================================"
Write-Info "  1. Keep this window open"
Write-Info "  2. On your phone, tap the ScanDoc app icon"
Write-Info "  3. Wait for the crash to happen"
Write-Info "  4. Press Ctrl+C to stop log capture"
Write-Info ""
Write-Info "  Logs will be saved to: crash_logs.txt"
Write-Info "============================================================================"
Write-Host ""

Write-Success "Starting log capture..."
Write-Host ""

# Capture logs
& $adbPath logcat -v time | Tee-Object -FilePath "crash_logs.txt"

