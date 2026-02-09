$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host ""
Write-Host "Clearing logs..." -ForegroundColor Yellow
& $adb logcat -c

Write-Host "Logs cleared." -ForegroundColor Green
Write-Host ""
Write-Host "Please open the ScanDoc app now..." -ForegroundColor Cyan
Write-Host "Waiting 5 seconds for app to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "Capturing startup logs..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  STARTUP LOGS" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

$logs = & $adb logcat -d -s MainActivity:* TesseractHelper:* PagesFragment:* AndroidRuntime:E
Write-Host $logs

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking files on device..." -ForegroundColor Yellow
$marExists = & $adb shell "test -f /data/data/com.mk.scandoc/files/tessdata/mar.traineddata && echo EXISTS || echo MISSING"
$engExists = & $adb shell "test -f /data/data/com.mk.scandoc/files/tessdata/eng.traineddata && echo EXISTS || echo MISSING"

Write-Host "  mar.traineddata: $marExists" -ForegroundColor $(if ($marExists -match "EXISTS") { "Green" } else { "Red" })
Write-Host "  eng.traineddata: $engExists" -ForegroundColor $(if ($engExists -match "EXISTS") { "Green" } else { "Red" })

if ($marExists -match "EXISTS" -and $engExists -match "EXISTS") {
    Write-Host ""
    Write-Host "Checking file sizes..." -ForegroundColor Yellow
    $marSize = & $adb shell "stat -c%s /data/data/com.mk.scandoc/files/tessdata/mar.traineddata"
    $engSize = & $adb shell "stat -c%s /data/data/com.mk.scandoc/files/tessdata/eng.traineddata"
    
    Write-Host "  mar.traineddata: $marSize bytes" -ForegroundColor $(if ([long]$marSize.Trim() -gt 10485760) { "Green" } else { "Red" })
    Write-Host "  eng.traineddata: $engSize bytes" -ForegroundColor $(if ([long]$engSize.Trim() -gt 4194304) { "Green" } else { "Red" })
}

Write-Host ""

