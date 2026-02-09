# ============================================================================
# ScanDoc - Automated Full Diagnostic Script
# ============================================================================

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$apkPath = "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_20260131_144527.apk"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  ScanDoc - Automated Full Diagnostic Workflow" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if ADB exists
if (-not (Test-Path $adb)) {
    Write-Host "[ERROR] ADB not found at: $adb" -ForegroundColor Red
    Write-Host "Please install Android SDK Platform Tools" -ForegroundColor Red
    exit 1
}

# Check if APK exists
if (-not (Test-Path $apkPath)) {
    Write-Host "[ERROR] APK not found at: $apkPath" -ForegroundColor Red
    exit 1
}

# Check if device is connected
Write-Host "[0/8] Checking device connection..." -ForegroundColor Yellow
$devices = & $adb devices
if ($devices -match "device$") {
    Write-Host "  Device connected" -ForegroundColor Green
} else {
    Write-Host "  ERROR: No device connected!" -ForegroundColor Red
    Write-Host "  Please connect your Android device via USB and enable USB debugging" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 1: Uninstall old app
Write-Host "[1/8] Uninstalling old app (clearing all data)..." -ForegroundColor Yellow
$uninstallResult = & $adb uninstall com.mk.scandoc 2>&1
if ($uninstallResult -match "Success") {
    Write-Host "  Old app uninstalled successfully" -ForegroundColor Green
} elseif ($uninstallResult -match "not installed") {
    Write-Host "  App was not installed (fresh install)" -ForegroundColor Green
} else {
    Write-Host "  Uninstall result: $uninstallResult" -ForegroundColor Yellow
}
Write-Host ""

# Step 2: Install new APK
Write-Host "[2/8] Installing new diagnostic APK..." -ForegroundColor Yellow
Write-Host "  APK: ScanDoc_Debug_20260131_144527.apk" -ForegroundColor White
$installResult = & $adb install -r $apkPath 2>&1
if ($installResult -match "Success") {
    Write-Host "  APK installed successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Installation failed!" -ForegroundColor Red
    Write-Host "  $installResult" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Clear logs
Write-Host "[3/8] Clearing logcat buffer..." -ForegroundColor Yellow
& $adb logcat -c
Write-Host "  Logs cleared" -ForegroundColor Green
Write-Host ""

# Step 4: Launch app automatically
Write-Host "[4/8] Launching ScanDoc app..." -ForegroundColor Yellow
& $adb shell am start -n com.mk.scandoc/.MainActivity 2>&1 | Out-Null
Write-Host "  App launched" -ForegroundColor Green
Write-Host "  Waiting 15 seconds for app startup and file copy..." -ForegroundColor Yellow

# Progress bar for waiting
for ($i = 1; $i -le 15; $i++) {
    Write-Progress -Activity "Waiting for app startup" -Status "Elapsed: $i/15 seconds" -PercentComplete (($i / 15) * 100)
    Start-Sleep -Seconds 1
}
Write-Progress -Activity "Waiting for app startup" -Completed
Write-Host "  Wait complete" -ForegroundColor Green
Write-Host ""

# Step 5: Capture startup logs
Write-Host "[5/8] Capturing startup logs..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  STARTUP LOGS (MainActivity + TesseractHelper)" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
$startupLogs = & $adb logcat -d -s MainActivity:D MainActivity:E TesseractHelper:D TesseractHelper:E
Write-Host $startupLogs
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 6: Check files on device
Write-Host "[6/8] Checking files on device..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  [6a] Directory listing:" -ForegroundColor Cyan
$dirListing = & $adb shell "ls -lh /data/data/com.mk.scandoc/files/tessdata/ 2>&1"
Write-Host $dirListing
Write-Host ""

Write-Host "  [6b] File existence check:" -ForegroundColor Cyan
$marExists = & $adb shell 'test -f /data/data/com.mk.scandoc/files/tessdata/mar.traineddata && echo EXISTS || echo MISSING'
$engExists = & $adb shell 'test -f /data/data/com.mk.scandoc/files/tessdata/eng.traineddata && echo EXISTS || echo MISSING'
$marExists = $marExists.Trim()
$engExists = $engExists.Trim()
Write-Host "    mar.traineddata: $marExists" -ForegroundColor $(if ($marExists -match "EXISTS") { "Green" } else { "Red" })
Write-Host "    eng.traineddata: $engExists" -ForegroundColor $(if ($engExists -match "EXISTS") { "Green" } else { "Red" })
Write-Host ""

# Step 7: Check file sizes (if files exist)
if ($marExists -match "EXISTS" -and $engExists -match "EXISTS") {
    Write-Host "  [6c] File sizes:" -ForegroundColor Cyan
    $marSizeRaw = & $adb shell 'stat -c%s /data/data/com.mk.scandoc/files/tessdata/mar.traineddata'
    $engSizeRaw = & $adb shell 'stat -c%s /data/data/com.mk.scandoc/files/tessdata/eng.traineddata'

    $marSize = [long]$marSizeRaw.Trim()
    $engSize = [long]$engSizeRaw.Trim()

    $marMB = [math]::Round($marSize / 1MB, 2)
    $engMB = [math]::Round($engSize / 1MB, 2)

    $marColor = if ($marSize -gt 10485760) { "Green" } else { "Red" }
    $engColor = if ($engSize -gt 4194304) { "Green" } else { "Red" }

    Write-Host "    mar.traineddata: $marSize bytes" -ForegroundColor $marColor
    Write-Host "    eng.traineddata: $engSize bytes" -ForegroundColor $engColor
    Write-Host ""

    if ($marSize -lt 10485760) {
        Write-Host "    WARNING: mar.traineddata is too small" -ForegroundColor Red
    }
    if ($engSize -lt 4194304) {
        Write-Host "    WARNING: eng.traineddata is too small" -ForegroundColor Red
    }
}
Write-Host ""

# Step 8: Analyze logs for critical information
Write-Host "[7/8] Analyzing logs for critical diagnostic information..." -ForegroundColor Yellow
Write-Host ""

# Extract key diagnostic lines
$assetCountLine = $startupLogs | Select-String "Assets in APK tessdata folder:"
$copySuccessLine = $startupLogs | Select-String 'copyTessDataFiles\(\) END'
$filesVerifiedLine = $startupLogs | Select-String "All required files copied and verified"

Write-Host "  [7a] Asset Detection:" -ForegroundColor Cyan
if ($assetCountLine) {
    Write-Host "    $assetCountLine" -ForegroundColor White
    if ($assetCountLine -match "Assets in APK tessdata folder: 0") {
        Write-Host "    CRITICAL: No assets found in APK!" -ForegroundColor Red
    } elseif ($assetCountLine -match "Assets in APK tessdata folder: 2") {
        Write-Host "    OK: Assets found in APK" -ForegroundColor Green
    }
} else {
    Write-Host "    WARNING: Asset count line not found in logs" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "  [7b] Copy Operation Result:" -ForegroundColor Cyan
if ($copySuccessLine) {
    Write-Host "    $copySuccessLine" -ForegroundColor White
    if ($copySuccessLine -match "SUCCESS") {
        Write-Host "    OK: Copy operation succeeded" -ForegroundColor Green
    } elseif ($copySuccessLine -match "FAILURE") {
        Write-Host "    ERROR: Copy operation failed!" -ForegroundColor Red
    }
} else {
    Write-Host "    WARNING: Copy result line not found in logs" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "  [7c] File Verification:" -ForegroundColor Cyan
if ($filesVerifiedLine) {
    Write-Host "    $filesVerifiedLine" -ForegroundColor Green
} else {
    Write-Host "    WARNING: File verification line not found" -ForegroundColor Yellow
}
Write-Host ""

Write-Host ""
Write-Host "Diagnostic script complete" -ForegroundColor Green
Write-Host ""
