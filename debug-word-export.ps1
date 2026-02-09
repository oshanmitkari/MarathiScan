# ========================================
#  DEBUG WORD EXPORT - OPPO A5 PRO
# ========================================

Write-Host ""
Write-Host "DEBUG WORD EXPORT ISSUE" -ForegroundColor Cyan
Write-Host ""

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Check device
Write-Host "[1/6] Checking device connection..." -ForegroundColor Yellow
$devices = & $adb devices
if ($devices -match "device$") {
    Write-Host "  [OK] Device connected" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] No device found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Get device info
Write-Host "[2/6] Getting device information..." -ForegroundColor Yellow
$manufacturer = & $adb shell getprop ro.product.manufacturer
$model = & $adb shell getprop ro.product.model
$androidVersion = & $adb shell getprop ro.build.version.release
$sdkVersion = & $adb shell getprop ro.build.version.sdk

Write-Host "  Manufacturer: $manufacturer" -ForegroundColor White
Write-Host "  Model: $model" -ForegroundColor White
Write-Host "  Android Version: $androidVersion" -ForegroundColor White
Write-Host "  SDK Version: $sdkVersion" -ForegroundColor White
Write-Host ""

# Clear logs
Write-Host "[3/6] Clearing logs..." -ForegroundColor Yellow
& $adb logcat -c
Write-Host "  [OK] Logs cleared" -ForegroundColor Green
Write-Host ""

# Instructions
Write-Host "[4/6] PLEASE DO THE FOLLOWING ON YOUR PHONE:" -ForegroundColor Cyan
Write-Host "  1. Open ScanDoc app" -ForegroundColor White
Write-Host "  2. Go to 'Pages' tab" -ForegroundColor White
Write-Host "  3. Click 'Export Word DOCX' button" -ForegroundColor White
Write-Host "  4. Wait for any message" -ForegroundColor White
Write-Host ""
Write-Host "  Press ENTER after you clicked the button..." -ForegroundColor Yellow
Read-Host

# Capture logs
Write-Host "[5/6] Capturing export logs..." -ForegroundColor Yellow
Write-Host ""

$logs = & $adb logcat -d | Select-String "PagesFragment|exportWord|DOCX|Export"

if ($logs) {
    Write-Host "  EXPORT LOGS:" -ForegroundColor Cyan
    Write-Host ""
    $logs | ForEach-Object {
        $line = $_.Line
        if ($line -match "ERROR|error|Error") {
            Write-Host "  [ERROR] $line" -ForegroundColor Red
        } elseif ($line -match "WARNING|warning|Warning") {
            Write-Host "  [WARN] $line" -ForegroundColor Yellow
        } elseif ($line -match "OK|success|Success|saved") {
            Write-Host "  [OK] $line" -ForegroundColor Green
        } else {
            Write-Host "  [INFO] $line" -ForegroundColor White
        }
    }
} else {
    Write-Host "  [WARN] No export logs found!" -ForegroundColor Yellow
}
Write-Host ""

# Check all possible file locations
Write-Host "[6/6] Checking all possible file locations..." -ForegroundColor Yellow
Write-Host ""

$locations = @(
    "/storage/emulated/0/Android/data/com.mk.scandoc/files/Documents/ScanDoc",
    "/storage/emulated/0/Download/ScanDoc",
    "/storage/emulated/0/Downloads/ScanDoc",
    "/sdcard/Android/data/com.mk.scandoc/files/Documents/ScanDoc",
    "/sdcard/Download/ScanDoc",
    "/sdcard/Downloads/ScanDoc",
    "/sdcard/Documents/ScanDoc"
)

$foundFiles = $false

foreach ($location in $locations) {
    Write-Host "  Checking: $location" -ForegroundColor Cyan
    $files = & $adb shell "ls -lh $location/*.docx 2>/dev/null"
    
    if ($files -and $files -notmatch "No such file") {
        Write-Host "    [OK] FOUND FILES!" -ForegroundColor Green
        $files | ForEach-Object {
            if ($_ -match "(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+\.docx)") {
                $size = $matches[4]
                $filename = $matches[6]
                Write-Host "      File: $filename ($size)" -ForegroundColor White
            }
        }
        $foundFiles = $true
    } else {
        Write-Host "    [X] No files" -ForegroundColor Gray
    }
}

Write-Host ""

if (-not $foundFiles) {
    Write-Host "NO DOCX FILES FOUND!" -ForegroundColor Red
    Write-Host ""
    Write-Host "POSSIBLE CAUSES:" -ForegroundColor Yellow
    Write-Host "  1. Export failed silently" -ForegroundColor White
    Write-Host "  2. Permission denied" -ForegroundColor White
    Write-Host "  3. Storage path issue on Oppo" -ForegroundColor White
    Write-Host "  4. OCR data not available" -ForegroundColor White
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "  1. Check the logs above for errors" -ForegroundColor White
    Write-Host "  2. Check if you see any error message on phone" -ForegroundColor White
    Write-Host "  3. Try granting storage permission manually" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "FILES FOUND!" -ForegroundColor Green
}

# Check storage permissions
Write-Host "Checking app permissions..." -ForegroundColor Yellow
$permissions = & $adb shell dumpsys package com.mk.scandoc | Select-String "permission"
Write-Host ""
Write-Host "  APP PERMISSIONS:" -ForegroundColor Cyan
$permissions | Select-Object -First 20 | ForEach-Object {
    Write-Host "    $_" -ForegroundColor White
}

Write-Host ""
Write-Host "DEBUG COMPLETE" -ForegroundColor Cyan
Write-Host ""

