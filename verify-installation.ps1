$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verifying ScanDoc Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking traineddata files on device..." -ForegroundColor Yellow
Write-Host ""

$fileList = & $adb shell "ls -lh /data/data/com.mk.scandoc/files/tessdata/" 2>&1

if ($fileList -match "traineddata") {
    Write-Host "Files found in tessdata directory:" -ForegroundColor Green
    Write-Host $fileList
} else {
    Write-Host "Directory listing:" -ForegroundColor Yellow
    Write-Host $fileList
}

Write-Host ""
Write-Host "Checking specific files..." -ForegroundColor Yellow

$marCheck = & $adb shell "ls -lh /data/data/com.mk.scandoc/files/tessdata/mar.traineddata" 2>&1
$engCheck = & $adb shell "ls -lh /data/data/com.mk.scandoc/files/tessdata/eng.traineddata" 2>&1

if ($marCheck -match "traineddata") {
    Write-Host "  mar.traineddata: $marCheck" -ForegroundColor Green
} else {
    Write-Host "  mar.traineddata: NOT FOUND" -ForegroundColor Red
}

if ($engCheck -match "traineddata") {
    Write-Host "  eng.traineddata: $engCheck" -ForegroundColor Green
} else {
    Write-Host "  eng.traineddata: NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking if app is running..." -ForegroundColor Yellow
$appProcess = & $adb shell "ps | grep scandoc" 2>&1

if ($appProcess -match "scandoc") {
    Write-Host "  App is RUNNING" -ForegroundColor Green
    Write-Host "  Process: $appProcess" -ForegroundColor White
} else {
    Write-Host "  App is NOT running" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

