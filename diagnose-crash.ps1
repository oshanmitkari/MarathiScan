# ============================================================================
# ScanDoc - Comprehensive Crash Diagnostic Tool
# ============================================================================

param(
    [switch]$CaptureLog
)

function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "============================================================================"
Write-Info "  ScanDoc - Crash Diagnostic Tool"
Write-Info "============================================================================"
Write-Host ""

# Find ADB
$androidHome = $env:ANDROID_HOME
if (-not $androidHome) {
    $androidHome = "$env:LOCALAPPDATA\Android\Sdk"
}

$adbPath = "$androidHome\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Error "ADB not found!"
    exit 1
}

Write-Info "[1/7] Checking device connection..."
$devices = & $adbPath devices | Select-String "device$"
if ($devices.Count -eq 0) {
    Write-Error "No device connected!"
    exit 1
}
Write-Success "  [OK] Device connected"
Write-Host ""

Write-Info "[2/7] Getting device information..."
$deviceModel = & $adbPath shell getprop ro.product.model
$androidVersion = & $adbPath shell getprop ro.build.version.release
$sdkVersion = & $adbPath shell getprop ro.build.version.sdk

Write-Info "  -> Device Model: $deviceModel"
Write-Info "  -> Android Version: $androidVersion (API $sdkVersion)"
Write-Host ""

Write-Info "[3/7] Checking if app is installed..."
$packageCheck = & $adbPath shell pm list packages | Select-String "com.mk.scandoc"
if ($packageCheck) {
    Write-Success "  [OK] App is installed"
} else {
    Write-Error "  [ERROR] App is NOT installed!"
    exit 1
}
Write-Host ""

Write-Info "[4/7] Checking app permissions..."
$permissions = & $adbPath shell dumpsys package com.mk.scandoc | Select-String "permission"
Write-Info "  Permissions status:"
Write-Host $permissions
Write-Host ""

Write-Info "[5/7] Checking traineddata files..."
$tessDataCheck = & $adbPath shell "run-as com.mk.scandoc ls -la /data/data/com.mk.scandoc/files/tessdata/ 2>&1"
if ($tessDataCheck -match "eng.traineddata") {
    Write-Success "  [OK] eng.traineddata found"
} else {
    Write-Warning "  [WARNING] eng.traineddata NOT found"
}

if ($tessDataCheck -match "mar.traineddata") {
    Write-Success "  [OK] mar.traineddata found"
} else {
    Write-Warning "  [WARNING] mar.traineddata NOT found"
}
Write-Host ""

Write-Info "[6/7] Checking recent crash logs..."
Write-Info "  Fetching last crash..."
$crashLog = & $adbPath logcat -d -v time AndroidRuntime:E *:S | Select-String -Pattern "com.mk.scandoc|FATAL" -Context 5,10
if ($crashLog) {
    Write-Error "  [CRASH DETECTED] Recent crash found:"
    Write-Host ""
    Write-Host $crashLog -ForegroundColor Red
} else {
    Write-Success "  [OK] No recent crashes in log"
}
Write-Host ""

Write-Info "[7/7] Checking for common crash causes..."
Write-Host ""

# Check for specific error patterns
$fullLog = & $adbPath logcat -d -v time
$hasNullPointer = $fullLog | Select-String "NullPointerException.*scandoc"
$hasClassNotFound = $fullLog | Select-String "ClassNotFoundException.*scandoc"
$hasUnsatisfiedLink = $fullLog | Select-String "UnsatisfiedLinkError"
$hasOutOfMemory = $fullLog | Select-String "OutOfMemoryError"

if ($hasNullPointer) {
    Write-Error "  [FOUND] NullPointerException detected"
    Write-Host $hasNullPointer -ForegroundColor Red
}

if ($hasClassNotFound) {
    Write-Error "  [FOUND] ClassNotFoundException detected"
    Write-Host $hasClassNotFound -ForegroundColor Red
}

if ($hasUnsatisfiedLink) {
    Write-Error "  [FOUND] UnsatisfiedLinkError detected (native library issue)"
    Write-Host $hasUnsatisfiedLink -ForegroundColor Red
}

if ($hasOutOfMemory) {
    Write-Error "  [FOUND] OutOfMemoryError detected"
    Write-Host $hasOutOfMemory -ForegroundColor Red
}

Write-Host ""
Write-Info "============================================================================"
Write-Info "  Diagnostic Summary"
Write-Info "============================================================================"
Write-Host ""

if ($CaptureLog) {
    Write-Info "Capturing live crash log..."
    Write-Info "Please launch the app now and wait for crash..."
    Write-Host ""
    
    & $adbPath logcat -c
    & $adbPath logcat -v time | Tee-Object -FilePath "crash_diagnostic.txt"
}

Write-Success "Diagnostic complete!"
Write-Host ""
Write-Info "To capture live crash log, run:"
Write-Info "  .\diagnose-crash.ps1 -CaptureLog"
Write-Host ""

