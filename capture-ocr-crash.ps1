# Capture OCR initialization crash logs
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$logFile = "C:\Users\oshan\Desktop\scandoc_ocr_crash.txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CAPTURING OCR CRASH LOGS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Clear logcat
Write-Host "Clearing old logs..." -ForegroundColor Yellow
& $adb logcat -c

Write-Host "Capturing logs in real-time..." -ForegroundColor Yellow
Write-Host "Please click 'Run OCR' on your phone NOW" -ForegroundColor Green
Write-Host ""

# Capture logs for 15 seconds
$logJob = Start-Job -ScriptBlock {
    param($adbPath, $logPath)
    & $adbPath logcat > $logPath
} -ArgumentList $adb, $logFile

Write-Host "Waiting 15 seconds for crash to occur..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

Stop-Job $logJob
Remove-Job $logJob

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CRASH ANALYSIS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $logFile) {
    $logs = Get-Content $logFile
    
    # Look for crash indicators
    Write-Host "=== FATAL ERRORS ===" -ForegroundColor Red
    $fatalLogs = $logs | Select-String -Pattern "FATAL|AndroidRuntime|CRASH|died|signal 11|signal 6"
    if ($fatalLogs) {
        $fatalLogs | Select-Object -Last 50 | ForEach-Object {
            Write-Host $_.Line -ForegroundColor Red
        }
    } else {
        Write-Host "No fatal errors found" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=== TESSERACT INITIALIZATION ===" -ForegroundColor Yellow
    $tessLogs = $logs | Select-String -Pattern "TesseractHelper|PagesFragment.*init|tessAPI|TessBaseAPI|dataPath"
    if ($tessLogs) {
        $tessLogs | Select-Object -Last 50 | ForEach-Object {
            $line = $_.Line
            if ($line -match "ERROR|FATAL") {
                Write-Host $line -ForegroundColor Red
            } elseif ($line -match "SUCCESS|OK") {
                Write-Host $line -ForegroundColor Green
            } else {
                Write-Host $line -ForegroundColor White
            }
        }
    } else {
        Write-Host "No Tesseract initialization logs found" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== NATIVE CRASH (JNI) ===" -ForegroundColor Red
    $nativeLogs = $logs | Select-String -Pattern "libtess|liblept|JNI|native|signal 11|SIGSEGV|backtrace"
    if ($nativeLogs) {
        $nativeLogs | Select-Object -Last 50 | ForEach-Object {
            Write-Host $_.Line -ForegroundColor Red
        }
    } else {
        Write-Host "No native crash logs found" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=== OCR BUTTON CLICK ===" -ForegroundColor Cyan
    $ocrLogs = $logs | Select-String -Pattern "Run OCR|runOcr|OCR button|initTesseract"
    if ($ocrLogs) {
        $ocrLogs | Select-Object -Last 30 | ForEach-Object {
            Write-Host $_.Line -ForegroundColor White
        }
    }
    
} else {
    Write-Host "Log file not created!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Full log saved to: $logFile" -ForegroundColor Gray
Write-Host ""

