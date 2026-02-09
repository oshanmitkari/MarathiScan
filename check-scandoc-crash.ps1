$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host ""
Write-Host "Clearing logs..." -ForegroundColor Yellow
& $adb logcat -c

Write-Host "Logs cleared." -ForegroundColor Green
Write-Host ""
Write-Host "Please open the ScanDoc app now..." -ForegroundColor Cyan
Write-Host "Waiting 8 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host ""
Write-Host "Capturing ScanDoc-specific logs..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  SCANDOC APP LOGS" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

$logs = & $adb logcat -d | Select-String -Pattern "scandoc|ScanDoc|com.mk.scandoc" -Context 3,3
if ($logs) {
    Write-Host $logs
} else {
    Write-Host "NO SCANDOC LOGS FOUND!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checking for ANY crash logs..." -ForegroundColor Yellow
    $crashLogs = & $adb logcat -d | Select-String -Pattern "FATAL|crash|died" -Context 2,2
    if ($crashLogs) {
        Write-Host $crashLogs
    } else {
        Write-Host "No crash logs found either." -ForegroundColor Yellow
    }
}

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

