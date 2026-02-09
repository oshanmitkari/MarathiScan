# Script to diagnose current OCR issue

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OCR Issue Diagnosis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "This script will capture detailed logs during OCR operation." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please perform the following steps on your phone:" -ForegroundColor Cyan
Write-Host "  1. Make sure the ScanDoc app is open" -ForegroundColor White
Write-Host "  2. Make sure you have at least one page added" -ForegroundColor White
Write-Host "  3. Navigate to the Pages tab" -ForegroundColor White
Write-Host "  4. When ready, press ENTER here, then immediately click 'Run OCR' on your phone" -ForegroundColor White
Write-Host ""
Write-Host "Press ENTER to start monitoring..." -ForegroundColor Yellow
Read-Host

Write-Host ""
Write-Host "Clearing old logs..." -ForegroundColor Yellow
& $adb logcat -c
Start-Sleep -Seconds 1

Write-Host "Monitoring started. Click 'Run OCR' NOW on your phone..." -ForegroundColor Green
Write-Host "Waiting 15 seconds to capture logs..." -ForegroundColor Yellow
Write-Host ""

# Capture logs for 15 seconds
Start-Sleep -Seconds 15

Write-Host "Retrieving logs..." -ForegroundColor Yellow
$logs = & $adb logcat -d

# Save full logs
$logFile = "C:\Users\oshan\Desktop\scandoc_ocr_diagnosis.txt"
$logs | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "[OK] Full logs saved to: $logFile" -ForegroundColor Green
Write-Host ""

# Analyze logs
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Log Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Filter ScanDoc-related logs
$scanDocLogs = $logs | Select-String -Pattern "scandoc|PagesFragment|TesseractHelper|MainActivity" -CaseSensitive:$false

Write-Host "ScanDoc-related log entries: $($scanDocLogs.Count)" -ForegroundColor Cyan
Write-Host ""

# Check for specific issues
Write-Host "Checking for specific issues..." -ForegroundColor Yellow
Write-Host ""

# 1. Check for crashes
$crashes = $logs | Select-String -Pattern "FATAL|AndroidRuntime.*Exception|crash_dump" -CaseSensitive:$false
if ($crashes) {
    Write-Host "[ERROR] Found crash/exception:" -ForegroundColor Red
    $crashes | Select-Object -First 10 | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
    Write-Host ""
} else {
    Write-Host "[OK] No crashes detected" -ForegroundColor Green
}

# 2. Check for Tesseract initialization
$tessInit = $scanDocLogs | Select-String -Pattern "init|TessBaseAPI|tessAPI" -CaseSensitive:$false
if ($tessInit) {
    Write-Host "Tesseract initialization logs:" -ForegroundColor Cyan
    $tessInit | Select-Object -First 20 | ForEach-Object { Write-Host $_.Line }
    Write-Host ""
}

# 3. Check for OCR results
$ocrResults = $scanDocLogs | Select-String -Pattern "OCR|recognized|extracted|text result|getUTF8Text" -CaseSensitive:$false
if ($ocrResults) {
    Write-Host "OCR result logs:" -ForegroundColor Cyan
    $ocrResults | ForEach-Object { Write-Host $_.Line }
    Write-Host ""
} else {
    Write-Host "[WARNING] No OCR result logs found" -ForegroundColor Yellow
    Write-Host ""
}

# 4. Check for errors
$errors = $scanDocLogs | Select-String -Pattern "ERROR|FAIL|Exception|error" -CaseSensitive:$false
if ($errors) {
    Write-Host "Error messages:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
    Write-Host ""
}

# 5. Check for warnings
$warnings = $scanDocLogs | Select-String -Pattern "WARNING|WARN" -CaseSensitive:$false
if ($warnings) {
    Write-Host "Warning messages:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host $_.Line -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Diagnosis Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Full logs saved to: $logFile" -ForegroundColor Green
Write-Host ""

