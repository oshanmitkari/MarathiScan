# Check Tesseract initialization logs
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$logFile = "C:\Users\oshan\Desktop\scandoc_tesseract_logs.txt"

Write-Host "Capturing Tesseract logs..." -ForegroundColor Cyan

# Capture all logs
& $adb logcat -d > $logFile

# Filter for Tesseract-related logs
$logs = Get-Content $logFile
$tesseractLogs = $logs | Select-String -Pattern "TesseractHelper|MainActivity.*Tesseract|copyTrainedData|tessdata|traineddata|OCR"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TESSERACT INITIALIZATION LOGS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($tesseractLogs) {
    $tesseractLogs | Select-Object -Last 100 | ForEach-Object {
        $line = $_.Line
        if ($line -match "ERROR|FATAL|CRITICAL") {
            Write-Host $line -ForegroundColor Red
        } elseif ($line -match "SUCCESS|OK|\[OK\]") {
            Write-Host $line -ForegroundColor Green
        } elseif ($line -match "WARN") {
            Write-Host $line -ForegroundColor Yellow
        } else {
            Write-Host $line -ForegroundColor White
        }
    }
} else {
    Write-Host "No Tesseract logs found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Showing MainActivity logs instead:" -ForegroundColor Cyan
    $logs | Select-String -Pattern "MainActivity" | Select-Object -Last 20 | ForEach-Object {
        Write-Host $_.Line -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Full log saved to: $logFile" -ForegroundColor Gray
Write-Host ""

