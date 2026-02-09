$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$logFile = "C:\Users\oshan\Desktop\scandoc_full_logs.txt"

Write-Host ""
Write-Host "Step 1: Clearing old logs..." -ForegroundColor Yellow
& $adb logcat -c

Write-Host "Step 2: Launching ScanDoc app..." -ForegroundColor Yellow
& $adb shell am start -n com.mk.scandoc/.MainActivity

Write-Host "Step 3: Waiting 5 seconds for app to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "Step 4: Capturing all logs..." -ForegroundColor Yellow
& $adb logcat -d -v time > $logFile

Write-Host ""
Write-Host "Logs saved to: $logFile" -ForegroundColor Green
Write-Host ""

Write-Host "Searching for MainActivity logs..." -ForegroundColor Yellow
$mainActivityLogs = Select-String -Path $logFile -Pattern "MainActivity" -Context 0,2
if ($mainActivityLogs) {
    Write-Host "MainActivity logs found:" -ForegroundColor Green
    $mainActivityLogs | ForEach-Object { Write-Host $_.Line }
} else {
    Write-Host "NO MainActivity logs found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Searching for FATAL errors..." -ForegroundColor Yellow
$fatalErrors = Select-String -Path $logFile -Pattern "FATAL|AndroidRuntime.*FATAL" -Context 5,10
if ($fatalErrors) {
    Write-Host "FATAL errors found:" -ForegroundColor Red
    $fatalErrors | ForEach-Object { 
        Write-Host "---" -ForegroundColor Red
        Write-Host $_.Line -ForegroundColor Red
    }
} else {
    Write-Host "No FATAL errors found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Searching for scandoc package logs..." -ForegroundColor Yellow
$scanDocLogs = Select-String -Path $logFile -Pattern "com.mk.scandoc" -Context 1,1
if ($scanDocLogs) {
    Write-Host "ScanDoc package logs found:" -ForegroundColor Green
    $scanDocLogs | Select-Object -First 20 | ForEach-Object { Write-Host $_.Line }
} else {
    Write-Host "NO scandoc package logs found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Full log file available at: $logFile" -ForegroundColor Cyan
Write-Host "You can open it with: notepad $logFile" -ForegroundColor Cyan
Write-Host ""

