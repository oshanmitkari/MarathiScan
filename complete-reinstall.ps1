# Complete ScanDoc Reinstallation Script
# This script will uninstall, reinstall, and verify the ScanDoc app

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$apkPath = "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_FIXED.apk"
$packageName = "com.mk.scandoc"
$logFile = "C:\Users\oshan\Desktop\scandoc_reinstall_logs.txt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ScanDoc Complete Reinstallation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if device is connected
Write-Host "[1/7] Checking device connection..." -ForegroundColor Yellow
$devices = & $adb devices
if ($devices -match "device$") {
    Write-Host "  Device connected successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: No device connected!" -ForegroundColor Red
    Write-Host "  Please connect your Android device and enable USB debugging" -ForegroundColor Red
    exit 1
}

# Step 2: Uninstall old app
Write-Host ""
Write-Host "[2/7] Uninstalling old app..." -ForegroundColor Yellow
$uninstallResult = & $adb uninstall $packageName 2>&1
if ($uninstallResult -match "Success" -or $uninstallResult -match "DELETE_FAILED_INTERNAL_ERROR") {
    Write-Host "  Old app uninstalled successfully" -ForegroundColor Green
} else {
    Write-Host "  App was not installed (this is OK for first install)" -ForegroundColor Yellow
}

# Step 3: Verify APK exists and check file sizes
Write-Host ""
Write-Host "[3/7] Verifying APK file..." -ForegroundColor Yellow
if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length
    Write-Host "  APK found: $apkPath" -ForegroundColor Green
    Write-Host "  APK size: $([math]::Round($apkSize / 1MB, 2)) MB" -ForegroundColor Green
    
    # Extract and verify traineddata files in APK
    $tempDir = "C:\Users\oshan\Desktop\temp_apk_verify"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($apkPath, $tempDir)
    
    $marFile = Join-Path $tempDir "assets\tessdata\mar.traineddata"
    $engFile = Join-Path $tempDir "assets\tessdata\eng.traineddata"
    
    if (Test-Path $marFile) {
        $marSize = (Get-Item $marFile).Length
        Write-Host "  mar.traineddata: $([math]::Round($marSize / 1MB, 2)) MB" -ForegroundColor $(if ($marSize -gt 10485760) { "Green" } else { "Red" })
    } else {
        Write-Host "  ERROR: mar.traineddata NOT found in APK!" -ForegroundColor Red
        Remove-Item $tempDir -Recurse -Force
        exit 1
    }
    
    if (Test-Path $engFile) {
        $engSize = (Get-Item $engFile).Length
        Write-Host "  eng.traineddata: $([math]::Round($engSize / 1MB, 2)) MB" -ForegroundColor $(if ($engSize -gt 4194304) { "Green" } else { "Red" })
    } else {
        Write-Host "  ERROR: eng.traineddata NOT found in APK!" -ForegroundColor Red
        Remove-Item $tempDir -Recurse -Force
        exit 1
    }
    
    Remove-Item $tempDir -Recurse -Force
} else {
    Write-Host "  ERROR: APK not found at $apkPath" -ForegroundColor Red
    exit 1
}

# Step 4: Install new APK
Write-Host ""
Write-Host "[4/7] Installing new APK..." -ForegroundColor Yellow
$installResult = & $adb install -r $apkPath 2>&1
if ($installResult -match "Success") {
    Write-Host "  APK installed successfully" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Installation failed!" -ForegroundColor Red
    Write-Host "  $installResult" -ForegroundColor Red
    exit 1
}

# Step 5: Clear logcat and launch app
Write-Host ""
Write-Host "[5/7] Launching app and monitoring initialization..." -ForegroundColor Yellow
& $adb logcat -c
Write-Host "  Logs cleared" -ForegroundColor Green
Write-Host "  Launching ScanDoc..." -ForegroundColor Green
& $adb shell am start -n com.mk.scandoc/.MainActivity | Out-Null

# Step 6: Wait and capture logs
Write-Host ""
Write-Host "[6/7] Waiting for app initialization (5 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "  Capturing logs..." -ForegroundColor Green
& $adb logcat -d -v time > $logFile

# Step 7: Analyze logs
Write-Host ""
Write-Host "[7/7] Analyzing initialization logs..." -ForegroundColor Yellow
Write-Host ""

$mainActivityLogs = Select-String -Path $logFile -Pattern "MainActivity.*onCreate|Tesseract|traineddata" -Context 0,1

if ($mainActivityLogs) {
    Write-Host "  MainActivity Initialization Logs:" -ForegroundColor Cyan
    Write-Host "  =================================" -ForegroundColor Cyan
    foreach ($log in $mainActivityLogs) {
        $line = $log.Line
        if ($line -match "\[OK\]|\[SUCCESS\]|copied successfully") {
            Write-Host "  $line" -ForegroundColor Green
        } elseif ($line -match "\[ERROR\]|\[FATAL\]|failed") {
            Write-Host "  $line" -ForegroundColor Red
        } else {
            Write-Host "  $line" -ForegroundColor White
        }
    }
} else {
    Write-Host "  WARNING: No MainActivity logs found!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Checking file copy status on device..." -ForegroundColor Cyan
$marExists = & $adb shell "test -f /data/data/com.mk.scandoc/files/tessdata/mar.traineddata && echo EXISTS || echo MISSING"
$engExists = & $adb shell "test -f /data/data/com.mk.scandoc/files/tessdata/eng.traineddata && echo EXISTS || echo MISSING"

if ($marExists -match "EXISTS") {
    $marDeviceSize = & $adb shell "stat -c%s /data/data/com.mk.scandoc/files/tessdata/mar.traineddata"
    Write-Host "  mar.traineddata: EXISTS ($([math]::Round($marDeviceSize / 1MB, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "  mar.traineddata: MISSING" -ForegroundColor Red
}

if ($engExists -match "EXISTS") {
    $engDeviceSize = & $adb shell "stat -c%s /data/data/com.mk.scandoc/files/tessdata/eng.traineddata"
    Write-Host "  eng.traineddata: EXISTS ($([math]::Round($engDeviceSize / 1MB, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "  eng.traineddata: MISSING" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Reinstallation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Full logs saved to: $logFile" -ForegroundColor Cyan
Write-Host "You can view them with: notepad $logFile" -ForegroundColor Cyan
Write-Host ""

