# ========================================
#  WORD EXPORT TEST SCRIPT
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WORD EXPORT TEST - SCANDOC APP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Check device connection
Write-Host "[1/5] Checking device connection..." -ForegroundColor Yellow
$devices = & $adb devices
if ($devices -match "device$") {
    Write-Host "  ✅ Device connected" -ForegroundColor Green
} else {
    Write-Host "  ❌ No device found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check if app is running
Write-Host "[2/5] Checking if ScanDoc is running..." -ForegroundColor Yellow
$appRunning = & $adb shell "ps | grep com.mk.scandoc"
if ($appRunning) {
    Write-Host "  ✅ ScanDoc app is running" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  ScanDoc app is not running" -ForegroundColor Yellow
    Write-Host "  Launching app..." -ForegroundColor Yellow
    & $adb shell am start -n com.mk.scandoc/.MainActivity
    Start-Sleep -Seconds 2
}
Write-Host ""

# Monitor for export activity
Write-Host "[3/5] Monitoring for Word export activity..." -ForegroundColor Yellow
Write-Host "  Please perform the following steps on your phone:" -ForegroundColor Cyan
Write-Host "  1. Go to 'Pages' tab" -ForegroundColor White
Write-Host "  2. Click 'Export Word DOCX' button" -ForegroundColor White
Write-Host "  3. Wait for success message" -ForegroundColor White
Write-Host ""
Write-Host "  Monitoring logs (press Ctrl+C to stop)..." -ForegroundColor Yellow
Write-Host ""

# Clear logcat
& $adb logcat -c

# Monitor logs for 60 seconds
$timeout = 60
$startTime = Get-Date
$exportDetected = $false

while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
    $logs = & $adb logcat -d -s PagesFragment:D | Select-String "Exporting|DOCX saved|Export error"
    
    if ($logs) {
        foreach ($log in $logs) {
            if ($log -match "Exporting (\d+) pages to DOCX") {
                Write-Host "  📝 Export started: $($matches[1]) pages" -ForegroundColor Cyan
                $exportDetected = $true
            }
            if ($log -match "DOCX saved: (.+)") {
                Write-Host "  ✅ DOCX saved: $($matches[1])" -ForegroundColor Green
                $exportPath = $matches[1]
                $exportDetected = $true
                break
            }
            if ($log -match "Export error: (.+)") {
                Write-Host "  ❌ Export error: $($matches[1])" -ForegroundColor Red
                $exportDetected = $true
                break
            }
        }
        
        if ($exportDetected) {
            break
        }
    }
    
    Start-Sleep -Milliseconds 500
}

if (-not $exportDetected) {
    Write-Host "  ⚠️  No export activity detected in $timeout seconds" -ForegroundColor Yellow
    Write-Host "  Please make sure you clicked 'Export Word DOCX' button" -ForegroundColor Yellow
}
Write-Host ""

# List exported files
Write-Host "[4/5] Listing exported DOCX files..." -ForegroundColor Yellow

# Try Android 10+ location first
$android10Path = "/storage/emulated/0/Android/data/com.mk.scandoc/files/Documents/ScanDoc"
$files = & $adb shell "ls -lh $android10Path/*.docx 2>/dev/null"

if ($files) {
    Write-Host "  📁 Location: $android10Path" -ForegroundColor Cyan
    Write-Host ""
    $files | ForEach-Object {
        if ($_ -match "(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+\.docx)") {
            $size = $matches[4]
            $filename = $matches[6]
            Write-Host "    📄 $filename ($size)" -ForegroundColor White
        }
    }
} else {
    # Try Android 9- location
    $android9Path = "/storage/emulated/0/Download/ScanDoc"
    $files = & $adb shell "ls -lh $android9Path/*.docx 2>/dev/null"
    
    if ($files) {
        Write-Host "  📁 Location: $android9Path" -ForegroundColor Cyan
        Write-Host ""
        $files | ForEach-Object {
            if ($_ -match "(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+\.docx)") {
                $size = $matches[4]
                $filename = $matches[6]
                Write-Host "    📄 $filename ($size)" -ForegroundColor White
            }
        }
    } else {
        Write-Host "  ⚠️  No DOCX files found" -ForegroundColor Yellow
    }
}
Write-Host ""

# Offer to pull latest file
Write-Host "[5/5] Pull latest DOCX file to computer?" -ForegroundColor Yellow
$response = Read-Host "  Enter 'y' to pull file, or any other key to skip"

if ($response -eq 'y' -or $response -eq 'Y') {
    # Get latest file
    if ($android10Path) {
        $latestFile = & $adb shell "ls -t $android10Path/*.docx 2>/dev/null | head -1"
    } else {
        $latestFile = & $adb shell "ls -t $android9Path/*.docx 2>/dev/null | head -1"
    }
    
    if ($latestFile) {
        $latestFile = $latestFile.Trim()
        $filename = Split-Path $latestFile -Leaf
        $destPath = Join-Path $PSScriptRoot $filename
        
        Write-Host "  Pulling file..." -ForegroundColor Yellow
        & $adb pull $latestFile $destPath
        
        if (Test-Path $destPath) {
            Write-Host "  ✅ File saved to: $destPath" -ForegroundColor Green
            Write-Host ""
            Write-Host "  Opening file..." -ForegroundColor Yellow
            Start-Process $destPath
        } else {
            Write-Host "  ❌ Failed to pull file" -ForegroundColor Red
        }
    } else {
        Write-Host "  ❌ No DOCX file found to pull" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

