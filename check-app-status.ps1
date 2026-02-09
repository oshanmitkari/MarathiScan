# Check if app is running and get recent logs

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "Checking app status..." -ForegroundColor Yellow
Write-Host ""

# Check if app process is running
$process = & $adb shell "ps | grep scandoc" 2>&1

if ($process -match "scandoc") {
    Write-Host "[OK] App is running" -ForegroundColor Green
    Write-Host $process
} else {
    Write-Host "[ERROR] App is NOT running (crashed or closed)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Recent app logs:" -ForegroundColor Cyan
& $adb logcat -d -s "PagesFragment:*" "MainActivity:*" | Select-Object -Last 20

Write-Host ""
Write-Host "Checking for crashes..." -ForegroundColor Yellow
$crashes = & $adb logcat -d | Select-String -Pattern "scandoc.*died|scandoc.*crash|STATE_DEAD.*scandoc" -Context 2,2

if ($crashes) {
    Write-Host "[ERROR] Found crash evidence:" -ForegroundColor Red
    $crashes | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
} else {
    Write-Host "[OK] No crash evidence found" -ForegroundColor Green
}

