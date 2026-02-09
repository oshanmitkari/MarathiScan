$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host ""
Write-Host "Checking if ScanDoc app is running..." -ForegroundColor Yellow

$processes = & $adb shell "ps | grep com.mk.scandoc"
if ($processes) {
    Write-Host "App is RUNNING:" -ForegroundColor Green
    Write-Host $processes
} else {
    Write-Host "App is NOT running!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking for MainActivity and TesseractHelper logs..." -ForegroundColor Yellow
$mainLogs = & $adb logcat -d | Select-String -Pattern "MainActivity|TesseractHelper"
if ($mainLogs) {
    Write-Host "Found logs:" -ForegroundColor Green
    Write-Host $mainLogs
} else {
    Write-Host "NO MainActivity or TesseractHelper logs found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking traineddata files on device..." -ForegroundColor Yellow
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

