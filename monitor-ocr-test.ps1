# Monitor OCR Test - Real-time log capture
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$logFile = "C:\Users\oshan\Desktop\scandoc_ocr_test_live.txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OCR TEST MONITOR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "1. Scan a document using the Scan tab" -ForegroundColor White
Write-Host "2. Go to the Pages tab" -ForegroundColor White
Write-Host "3. Click 'Run OCR' button" -ForegroundColor White
Write-Host "4. Watch the logs below in real-time" -ForegroundColor White
Write-Host ""

# Clear logcat
& $adb logcat -c

Write-Host "========================================" -ForegroundColor Green
Write-Host "  MONITORING STARTED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Start real-time monitoring
$logJob = Start-Job -ScriptBlock {
    param($adbPath, $logPath)
    & $adbPath logcat -v time | Tee-Object -FilePath $logPath
} -ArgumentList $adb, $logFile

# Monitor for 60 seconds
$startTime = Get-Date
$duration = 60

Write-Host "Monitoring for $duration seconds..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop early" -ForegroundColor Gray
Write-Host ""

while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
    if (Test-Path $logFile) {
        $newLogs = Get-Content $logFile -Tail 5 -ErrorAction SilentlyContinue
        
        foreach ($log in $newLogs) {
            if ($log -match "PagesFragment|TesseractHelper|tessAPI|OCR|initTesseract") {
                if ($log -match "ERROR|FATAL|CRASH|died") {
                    Write-Host $log -ForegroundColor Red
                } elseif ($log -match "SUCCESS|OK|\[OK\]") {
                    Write-Host $log -ForegroundColor Green
                } elseif ($log -match "WARN") {
                    Write-Host $log -ForegroundColor Yellow
                } elseif ($log -match "init|Tesseract|OCR") {
                    Write-Host $log -ForegroundColor Cyan
                }
            }
        }
    }
    
    Start-Sleep -Milliseconds 500
}

Stop-Job $logJob
Remove-Job $logJob

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MONITORING COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Full log saved to: $logFile" -ForegroundColor Gray
Write-Host ""

# Analyze the logs
if (Test-Path $logFile) {
    $allLogs = Get-Content $logFile
    
    Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
    
    $crashLogs = $allLogs | Select-String -Pattern "FATAL|AndroidRuntime|CRASH"
    if ($crashLogs) {
        Write-Host "❌ CRASH DETECTED!" -ForegroundColor Red
        $crashLogs | Select-Object -Last 20 | ForEach-Object {
            Write-Host $_.Line -ForegroundColor Red
        }
    } else {
        Write-Host "✅ No crashes detected" -ForegroundColor Green
    }
    
    $ocrSuccess = $allLogs | Select-String -Pattern "OCR.*success|Tesseract.*initialized"
    if ($ocrSuccess) {
        Write-Host "✅ OCR initialization successful" -ForegroundColor Green
    }
    
    $extractedText = $allLogs | Select-String -Pattern "Extracted text|OCR result"
    if ($extractedText) {
        Write-Host "✅ Text extraction completed" -ForegroundColor Green
    }
}

Write-Host ""

