# Script to rebuild APK with all validation fixes and test OCR

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Final Rebuild and OCR Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "All Fixes Applied:" -ForegroundColor Green
Write-Host "  1. TesseractHelper.java: MIN_MAR_SIZE = 2MB (was 10MB)" -ForegroundColor Green
Write-Host "  2. PagesFragment.java: MIN_MAR_SIZE = 2MB (was 10MB)" -ForegroundColor Green
Write-Host "  3. MainActivity.java: MIN_MAR_SIZE = 2MB (was 10MB)" -ForegroundColor Green
Write-Host "  4. Using tessdata (Tesseract 4.x) instead of tessdata_best (Tesseract 5.x)" -ForegroundColor Green
Write-Host ""

$projectDir = "C:\Users\oshan\Desktop\DTP\ScanDoc"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$gradlew = "$projectDir\gradlew.bat"

# Fix JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"

# Step 1: Clean build
Write-Host "[1/8] Cleaning previous build..." -ForegroundColor Yellow
Set-Location $projectDir
& $gradlew clean | Out-Null
Write-Host "[OK] Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Build APK
Write-Host "[2/8] Building APK with all validation fixes..." -ForegroundColor Yellow
$buildOutput = & $gradlew assembleDebug 2>&1 | Out-String

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    Write-Host $buildOutput
    exit 1
}

$apkPath = "$projectDir\app\build\outputs\apk\debug\app-debug.apk"

if (-not (Test-Path $apkPath)) {
    Write-Host "[ERROR] APK not found!" -ForegroundColor Red
    exit 1
}

$apkSize = (Get-Item $apkPath).Length
$apkSizeMB = [math]::Round($apkSize / 1MB, 2)
Write-Host "[OK] APK built successfully: $apkSizeMB MB" -ForegroundColor Green
Write-Host ""

# Step 3: Uninstall old app
Write-Host "[3/8] Uninstalling old app completely..." -ForegroundColor Yellow
& $adb uninstall com.mk.scandoc 2>&1 | Out-Null
Start-Sleep -Seconds 2
Write-Host "[OK] Old app uninstalled" -ForegroundColor Green
Write-Host ""

# Step 4: Install new APK
Write-Host "[4/8] Installing new APK..." -ForegroundColor Yellow
$installOutput = & $adb install $apkPath 2>&1

if ($installOutput -match "Success") {
    Write-Host "[OK] APK installed successfully" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Installation failed!" -ForegroundColor Red
    Write-Host $installOutput
    exit 1
}
Write-Host ""

# Step 5: Launch app
Write-Host "[5/8] Launching app..." -ForegroundColor Yellow
& $adb logcat -c
Start-Sleep -Seconds 1
& $adb shell am start -n com.mk.scandoc/.MainActivity
Start-Sleep -Seconds 5

Write-Host "[OK] App launched" -ForegroundColor Green
Write-Host ""

# Step 6: Check initialization
Write-Host "[6/8] Verifying initialization..." -ForegroundColor Yellow
$initLogs = & $adb logcat -d -s "MainActivity:*" "TesseractHelper:*"

$success = $false
if ($initLogs -match "SUCCESS.*Tesseract traineddata files are ready") {
    Write-Host "[SUCCESS] Traineddata files initialized successfully!" -ForegroundColor Green
    $success = $true
} elseif ($initLogs -match "FATAL.*Failed") {
    Write-Host "[ERROR] Initialization failed!" -ForegroundColor Red
    $initLogs | Select-String -Pattern "ERROR|FATAL" | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
} else {
    Write-Host "[WARNING] Could not determine initialization status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Key initialization logs:" -ForegroundColor Cyan
$initLogs | Select-String -Pattern "mar\.traineddata|eng\.traineddata|SUCCESS|ERROR|FATAL" | Select-Object -Last 15 | ForEach-Object { Write-Host $_.Line }
Write-Host ""

if (-not $success) {
    Write-Host "[ERROR] App initialization failed. Cannot proceed with OCR test." -ForegroundColor Red
    exit 1
}

# Step 7: Prepare for OCR test
Write-Host "[7/8] Preparing for OCR test..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please perform the following on your phone:" -ForegroundColor Cyan
Write-Host "  1. Make sure you have at least one page added (with text)" -ForegroundColor White
Write-Host "  2. Navigate to the Pages tab" -ForegroundColor White
Write-Host "  3. When ready, press ENTER here, then click 'Run OCR' on your phone" -ForegroundColor White
Write-Host ""
Write-Host "Press ENTER to start OCR monitoring..." -ForegroundColor Yellow
Read-Host

# Step 8: Monitor OCR operation
Write-Host ""
Write-Host "[8/8] Monitoring OCR operation..." -ForegroundColor Yellow
& $adb logcat -c
Start-Sleep -Seconds 1

Write-Host "Click 'Run OCR' NOW on your phone..." -ForegroundColor Green
Write-Host "Monitoring for 20 seconds..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 20

$ocrLogs = & $adb logcat -d -s "PagesFragment:*" "TesseractHelper:*"

# Save logs
$logFile = "C:\Users\oshan\Desktop\scandoc_ocr_test_final.txt"
$ocrLogs | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OCR Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for crashes
if ($ocrLogs -match "FATAL|crash|died|STATE_DEAD") {
    Write-Host "[ERROR] App crashed during OCR!" -ForegroundColor Red
    $ocrLogs | Select-String -Pattern "FATAL|crash|ERROR" | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
} elseif ($ocrLogs -match "init.*completed|initialized successfully") {
    Write-Host "[SUCCESS] Tesseract initialized successfully!" -ForegroundColor Green
    
    if ($ocrLogs -match "OCR.*completed|recognized|extracted|getUTF8Text") {
        Write-Host "[SUCCESS] OCR operation completed!" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Tesseract initialized, but no OCR completion detected" -ForegroundColor Yellow
        Write-Host "       (OCR may still be running or you may not have clicked 'Run OCR')" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARNING] Could not determine OCR status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "OCR operation logs:" -ForegroundColor Cyan
$ocrLogs | Select-String -Pattern "init|OCR|Tesseract|recognized|ERROR|FATAL" | ForEach-Object { Write-Host $_.Line }

Write-Host ""
Write-Host "Full logs saved to: $logFile" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

