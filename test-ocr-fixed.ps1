# Script to test OCR functionality after fix

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OCR Functionality Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "This script will monitor the app while you test OCR functionality." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please perform the following steps on your phone:" -ForegroundColor Cyan
Write-Host "  1. Open the ScanDoc app (should already be open)" -ForegroundColor White
Write-Host "  2. Add a page with Marathi/English text (or use existing page)" -ForegroundColor White
Write-Host "  3. Navigate to the Pages tab" -ForegroundColor White
Write-Host "  4. Click the 'Run OCR' button" -ForegroundColor White
Write-Host "  5. Wait for OCR to complete" -ForegroundColor White
Write-Host ""
Write-Host "Press ENTER when you're ready to start monitoring..." -ForegroundColor Yellow
Read-Host

Write-Host ""
Write-Host "Clearing old logs..." -ForegroundColor Yellow
& $adb logcat -c
Start-Sleep -Seconds 1

Write-Host "Monitoring logs. Perform the OCR test now..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop monitoring when done." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Monitor logs in real-time
& $adb logcat -s "PagesFragment:*" "TesseractHelper:*" "MainActivity:*" "AndroidRuntime:E" "DEBUG:*"

