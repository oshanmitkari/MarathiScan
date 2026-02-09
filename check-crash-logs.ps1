$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host ""
Write-Host "Clearing logs..." -ForegroundColor Yellow
& $adb logcat -c

Write-Host "Logs cleared." -ForegroundColor Green
Write-Host ""
Write-Host "Please open the ScanDoc app now..." -ForegroundColor Cyan
Write-Host "Waiting 8 seconds for app to start (or crash)..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host ""
Write-Host "Capturing ALL logs..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  COMPLETE LOGCAT OUTPUT" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

$logs = & $adb logcat -d
Write-Host $logs

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

