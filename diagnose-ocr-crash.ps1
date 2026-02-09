$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$logFile = "C:\Users\oshan\Desktop\scandoc_ocr_crash_logs.txt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ScanDoc OCR Crash Diagnostics" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Clearing old logs..." -ForegroundColor Yellow
& $adb logcat -c
Write-Host "  Logs cleared" -ForegroundColor Green

Write-Host ""
Write-Host "Step 2: Starting log capture..." -ForegroundColor Yellow
Write-Host "  Monitoring for crashes, errors, and OCR-related logs" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  READY FOR TESTING" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please perform these steps on your phone:" -ForegroundColor Cyan
Write-Host "  1. Open the ScanDoc app (if not already open)" -ForegroundColor White
Write-Host "  2. Navigate to the Pages tab" -ForegroundColor White
Write-Host "  3. Click the 'Run OCR' button" -ForegroundColor White
Write-Host "  4. Wait for the crash to occur" -ForegroundColor White
Write-Host ""
Write-Host "Press ENTER after the app crashes..." -ForegroundColor Yellow
Read-Host

Write-Host ""
Write-Host "Step 3: Capturing crash logs..." -ForegroundColor Yellow
& $adb logcat -d -v time > $logFile
Write-Host "  Logs captured and saved to: $logFile" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4: Analyzing crash logs..." -ForegroundColor Yellow
Write-Host ""

# Search for FATAL errors
Write-Host "=== FATAL ERRORS ===" -ForegroundColor Red
$fatalErrors = Select-String -Path $logFile -Pattern "FATAL EXCEPTION|AndroidRuntime.*FATAL" -Context 0,20
if ($fatalErrors) {
    foreach ($error in $fatalErrors) {
        Write-Host $error.Line -ForegroundColor Red
        foreach ($contextLine in $error.Context.PostContext) {
            if ($contextLine -match "at com.mk.scandoc") {
                Write-Host $contextLine -ForegroundColor Yellow
            } else {
                Write-Host $contextLine -ForegroundColor White
            }
        }
        Write-Host ""
    }
} else {
    Write-Host "  No FATAL errors found" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== NATIVE CRASHES ===" -ForegroundColor Red
$nativeCrashes = Select-String -Path $logFile -Pattern "libtess|UnsatisfiedLinkError|JNI|native crash" -Context 2,2
if ($nativeCrashes) {
    foreach ($crash in $nativeCrashes) {
        Write-Host $crash.Line -ForegroundColor Red
    }
} else {
    Write-Host "  No native crashes found" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== TESSERACT ERRORS ===" -ForegroundColor Red
$tessErrors = Select-String -Path $logFile -Pattern "TesseractHelper|PagesFragment.*OCR|tessAPI|Tesseract.*error|Tesseract.*fail" -Context 1,3
if ($tessErrors) {
    foreach ($error in $tessErrors | Select-Object -First 30) {
        $line = $error.Line
        if ($line -match "ERROR|FATAL|Exception|crash") {
            Write-Host $line -ForegroundColor Red
        } elseif ($line -match "WARN") {
            Write-Host $line -ForegroundColor Yellow
        } else {
            Write-Host $line -ForegroundColor White
        }
    }
} else {
    Write-Host "  No Tesseract-related logs found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== OUT OF MEMORY ERRORS ===" -ForegroundColor Red
$oomErrors = Select-String -Path $logFile -Pattern "OutOfMemory|OOM|memory.*low" -Context 1,1
if ($oomErrors) {
    foreach ($error in $oomErrors) {
        Write-Host $error.Line -ForegroundColor Red
    }
} else {
    Write-Host "  No out of memory errors found" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== NULL POINTER EXCEPTIONS ===" -ForegroundColor Red
$npeErrors = Select-String -Path $logFile -Pattern "NullPointerException.*scandoc" -Context 0,5
if ($npeErrors) {
    foreach ($error in $npeErrors) {
        Write-Host $error.Line -ForegroundColor Red
        foreach ($contextLine in $error.Context.PostContext) {
            Write-Host $contextLine -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  No null pointer exceptions found" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== APP PROCESS STATUS ===" -ForegroundColor Cyan
$appProcess = & $adb shell "ps | grep scandoc" 2>&1
if ($appProcess -match "scandoc") {
    Write-Host "  App is still RUNNING (no crash detected)" -ForegroundColor Green
    Write-Host "  $appProcess" -ForegroundColor White
} else {
    Write-Host "  App is NOT running (crashed or closed)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== COMPLETE SCANDOC LOGS (Last 50 lines) ===" -ForegroundColor Cyan
$scanDocLogs = Select-String -Path $logFile -Pattern "com.mk.scandoc|MainActivity|PagesFragment|TesseractHelper" | Select-Object -Last 50
if ($scanDocLogs) {
    foreach ($log in $scanDocLogs) {
        $line = $log.Line
        if ($line -match "ERROR|FATAL|Exception") {
            Write-Host $line -ForegroundColor Red
        } elseif ($line -match "WARN") {
            Write-Host $line -ForegroundColor Yellow
        } elseif ($line -match "SUCCESS|OK") {
            Write-Host $line -ForegroundColor Green
        } else {
            Write-Host $line -ForegroundColor White
        }
    }
} else {
    Write-Host "  No ScanDoc logs found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Analysis Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Full logs saved to: $logFile" -ForegroundColor Cyan
Write-Host "You can view them with: notepad $logFile" -ForegroundColor Cyan
Write-Host ""

