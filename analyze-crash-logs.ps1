$logFile = "C:\Users\oshan\Desktop\scandoc_ocr_crash_logs.txt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Detailed Crash Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $logFile)) {
    Write-Host "ERROR: Log file not found: $logFile" -ForegroundColor Red
    exit 1
}

Write-Host "=== SEARCHING FOR SCANDOC APP LOGS ===" -ForegroundColor Yellow
Write-Host ""

$scanDocLogs = Select-String -Path $logFile -Pattern "PagesFragment|TesseractHelper|MainActivity.*scandoc|com.mk.scandoc.*Exception|com.mk.scandoc.*Error"

if ($scanDocLogs) {
    Write-Host "Found $($scanDocLogs.Count) ScanDoc-related log lines" -ForegroundColor Green
    Write-Host ""
    
    foreach ($logEntry in $scanDocLogs) {
        $line = $logEntry.Line
        if ($line -match "ERROR|FATAL|Exception|crash|died") {
            Write-Host $line -ForegroundColor Red
        } elseif ($line -match "WARN") {
            Write-Host $line -ForegroundColor Yellow
        } elseif ($line -match "tessAPI|Tesseract|OCR") {
            Write-Host $line -ForegroundColor Cyan
        } else {
            Write-Host $line -ForegroundColor White
        }
    }
} else {
    Write-Host "No ScanDoc app logs found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SEARCHING FOR CRASH STACK TRACES ===" -ForegroundColor Yellow
Write-Host ""

$crashLines = Select-String -Path $logFile -Pattern "FATAL EXCEPTION|AndroidRuntime" -Context 0,30

if ($crashLines) {
    foreach ($crashEntry in $crashLines) {
        Write-Host $crashEntry.Line -ForegroundColor Red
        foreach ($contextLine in $crashEntry.Context.PostContext) {
            Write-Host $contextLine -ForegroundColor White
        }
        Write-Host ""
    }
} else {
    Write-Host "No FATAL EXCEPTION stack traces found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SEARCHING FOR PROCESS DEATH ===" -ForegroundColor Yellow
Write-Host ""

$deathLogs = Select-String -Path $logFile -Pattern "died|death|killed|crash.*scandoc|scandoc.*crash" -Context 2,2

if ($deathLogs) {
    foreach ($deathEntry in $deathLogs | Select-Object -First 10) {
        Write-Host $deathEntry.Line -ForegroundColor Red
    }
} else {
    Write-Host "No process death logs found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SEARCHING FOR SIGNAL/SEGFAULT ===" -ForegroundColor Yellow
Write-Host ""

$signalLogs = Select-String -Path $logFile -Pattern "signal|segfault|SIGSEGV|SIGABRT|backtrace" -Context 1,5

if ($signalLogs) {
    foreach ($signalEntry in $signalLogs | Select-Object -First 10) {
        Write-Host $signalEntry.Line -ForegroundColor Red
        foreach ($contextLine in $signalEntry.Context.PostContext) {
            Write-Host $contextLine -ForegroundColor White
        }
        Write-Host ""
    }
} else {
    Write-Host "No signal/segfault logs found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SEARCHING FOR LIBTESS NATIVE CRASH ===" -ForegroundColor Yellow
Write-Host ""

$libtessLogs = Select-String -Path $logFile -Pattern "libtess|tess.*so|JNI.*tess" -Context 3,3

if ($libtessLogs) {
    foreach ($libtessEntry in $libtessLogs | Select-Object -First 10) {
        Write-Host $libtessEntry.Line -ForegroundColor Red
        foreach ($contextLine in $libtessEntry.Context.PreContext) {
            Write-Host $contextLine -ForegroundColor Yellow
        }
        foreach ($contextLine in $libtessEntry.Context.PostContext) {
            Write-Host $contextLine -ForegroundColor Yellow
        }
        Write-Host ""
    }
} else {
    Write-Host "No libtess native library logs found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

