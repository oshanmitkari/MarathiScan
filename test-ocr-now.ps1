# Test OCR functionality

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OCR Functionality Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "  1. Make sure you have at least one page added in the app" -ForegroundColor White
Write-Host "  2. Navigate to the Pages tab" -ForegroundColor White
Write-Host "  3. Press ENTER here, then click 'Run OCR' on your phone" -ForegroundColor White
Write-Host ""
Read-Host "Press ENTER when ready"

Write-Host ""
Write-Host "Clearing logs and monitoring..." -ForegroundColor Yellow
& $adb logcat -c
Start-Sleep -Seconds 1

Write-Host "Click 'Run OCR' NOW on your phone!" -ForegroundColor Green
Write-Host "Monitoring for 30 seconds..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 30

$logs = & $adb logcat -d -s "PagesFragment:*" "TesseractHelper:*"

# Save logs
$logFile = "C:\Users\oshan\Desktop\scandoc_ocr_test_tessdata_fast.txt"
$logs | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OCR Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for crashes
$processCheck = & $adb shell "ps | grep scandoc" 2>&1

if ($processCheck -match "scandoc") {
    Write-Host "[OK] App is still running (no crash)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] App crashed!" -ForegroundColor Red
    
    # Check for crash evidence
    $crashLogs = & $adb logcat -d | Select-String -Pattern "scandoc.*died|APP CRASH" -Context 2,2
    if ($crashLogs) {
        Write-Host ""
        Write-Host "Crash evidence:" -ForegroundColor Red
        $crashLogs | Select-Object -First 5 | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
    }
}

Write-Host ""

# Check for initialization
if ($logs -match "init.*completed|initialized successfully") {
    Write-Host "[SUCCESS] Tesseract initialized!" -ForegroundColor Green
} elseif ($logs -match "Calling tessAPI\.init") {
    if ($logs -match "init.*completed") {
        Write-Host "[SUCCESS] Tesseract init completed!" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Init started but no completion message" -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] No initialization detected (OCR may not have been clicked)" -ForegroundColor Yellow
}

# Check for OCR completion
if ($logs -match "OCR.*completed|getUTF8Text|recognized") {
    Write-Host "[SUCCESS] OCR operation completed!" -ForegroundColor Green
} else {
    Write-Host "[INFO] No OCR completion detected" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Recent OCR logs:" -ForegroundColor Cyan
$logs | Select-String -Pattern "init|OCR|Tesseract|ERROR|FATAL" | Select-Object -Last 20 | ForEach-Object { Write-Host $_.Line }

Write-Host ""
Write-Host "Full logs saved to: $logFile" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

