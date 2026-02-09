$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host ""
Write-Host "Clearing logs and launching app..." -ForegroundColor Yellow
& $adb logcat -c
& $adb shell am start -n com.mk.scandoc/.MainActivity

Write-Host "Waiting 5 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "Searching for crash or error logs..." -ForegroundColor Yellow
Write-Host ""

$crashLogs = & $adb logcat -d | Select-String -Pattern "FATAL|AndroidRuntime|CRASH|Exception.*scandoc|Error.*scandoc" -Context 5,5
if ($crashLogs) {
    Write-Host "CRASH/ERROR LOGS FOUND:" -ForegroundColor Red
    Write-Host $crashLogs
} else {
    Write-Host "No crash logs found. Checking all scandoc logs..." -ForegroundColor Yellow
    $allLogs = & $adb logcat -d | Select-String -Pattern "scandoc" -Context 2,2
    if ($allLogs) {
        Write-Host $allLogs
    } else {
        Write-Host "NO scandoc logs at all!" -ForegroundColor Red
    }
}

Write-Host ""

