# Script to retrieve native crash tombstone

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Native Crash Tombstone Retrieval" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Searching for recent tombstone files..." -ForegroundColor Yellow
Write-Host ""

# List recent tombstones
$tombstoneList = & $adb shell "ls -lt /data/tombstones/ 2>/dev/null | head -10"

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tombstoneList)) {
    Write-Host "[WARNING] Cannot access /data/tombstones/ directory" -ForegroundColor Yellow
    Write-Host "This is normal on non-rooted devices." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Trying alternative method: logcat crash dump..." -ForegroundColor Yellow
    Write-Host ""
    
    # Search for native crash in logcat
    $crashLogs = & $adb logcat -d -s "DEBUG:*" "libc:*" "crash_dump64:*" | Select-String -Pattern "scandoc|libtess|liblept|SIGSEGV|SIGABRT" -Context 5,5
    
    if ($crashLogs) {
        Write-Host "Found native crash information in logcat:" -ForegroundColor Green
        Write-Host ""
        $crashLogs | ForEach-Object { Write-Host $_.Line }
    } else {
        Write-Host "[INFO] No native crash dump found in logcat" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This suggests the crash may be a silent termination rather than a SIGSEGV/SIGABRT." -ForegroundColor Yellow
    }
} else {
    Write-Host "Recent tombstone files:" -ForegroundColor Green
    Write-Host $tombstoneList
    Write-Host ""
    
    # Try to get the most recent tombstone
    $latestTombstone = & $adb shell "ls -t /data/tombstones/ 2>/dev/null | head -1"
    
    if ($latestTombstone) {
        Write-Host "Attempting to read latest tombstone: $latestTombstone" -ForegroundColor Yellow
        $tombstoneContent = & $adb shell "cat /data/tombstones/$latestTombstone 2>/dev/null"
        
        if ($tombstoneContent) {
            Write-Host ""
            Write-Host "Tombstone content:" -ForegroundColor Green
            Write-Host $tombstoneContent
        } else {
            Write-Host "[WARNING] Cannot read tombstone file (permission denied)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking for OOM (Out of Memory) errors..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$oomLogs = & $adb logcat -d | Select-String -Pattern "scandoc.*OutOfMemory|scandoc.*OOM|lowmemorykiller.*scandoc" -Context 2,2

if ($oomLogs) {
    Write-Host "Found OOM-related logs:" -ForegroundColor Red
    $oomLogs | ForEach-Object { Write-Host $_.Line }
} else {
    Write-Host "[OK] No OOM errors found" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Analysis Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

