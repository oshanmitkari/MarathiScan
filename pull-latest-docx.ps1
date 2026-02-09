# Pull Latest DOCX File from Android Device and Open in Word
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PULL LATEST DOCX FROM ANDROID DEVICE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set paths
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$androidPath = "/storage/emulated/0/Documents/ScanDoc/"
$desktopPath = "C:\Users\oshan\Desktop\"

# Check if ADB exists
if (-not (Test-Path $adb)) {
    Write-Host "[ERROR] ADB not found at: $adb" -ForegroundColor Red
    exit 1
}

# Check if device is connected
Write-Host "[1/4] Checking device connection..." -ForegroundColor Yellow
$devices = & $adb devices
if ($devices -match "device$") {
    Write-Host "  Device connected" -ForegroundColor Green
} else {
    Write-Host "  No device connected!" -ForegroundColor Red
    exit 1
}

# List DOCX files in the ScanDoc directory
Write-Host ""
Write-Host "[2/4] Finding latest DOCX file..." -ForegroundColor Yellow
$fileList = & $adb shell "ls -t $androidPath*.docx 2>/dev/null" 2>&1

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($fileList)) {
    Write-Host "  No DOCX files found in $androidPath" -ForegroundColor Red
    Write-Host "  Please export a DOCX file from the ScanDoc app first." -ForegroundColor Yellow
    exit 1
}

# Get the first (most recent) file
$latestFile = ($fileList -split "`n")[0].Trim()

if ([string]::IsNullOrWhiteSpace($latestFile)) {
    Write-Host "  Could not determine latest file" -ForegroundColor Red
    exit 1
}

Write-Host "  Latest file: $latestFile" -ForegroundColor Green

# Extract just the filename
$filename = Split-Path $latestFile -Leaf
$localPath = Join-Path $desktopPath $filename

Write-Host ""
Write-Host "[3/4] Pulling file from device..." -ForegroundColor Yellow
Write-Host "  From: $androidPath$filename" -ForegroundColor Gray
Write-Host "  To:   $localPath" -ForegroundColor Gray

# Pull the file
& $adb pull "$androidPath$filename" "$localPath" 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0 -and (Test-Path $localPath)) {
    $fileSize = (Get-Item $localPath).Length
    $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
    Write-Host "  File pulled successfully ($fileSizeKB KB)" -ForegroundColor Green
} else {
    Write-Host "  Failed to pull file" -ForegroundColor Red
    exit 1
}

# Open the file in Microsoft Word (or default DOCX handler)
Write-Host ""
Write-Host "[4/4] Opening file..." -ForegroundColor Yellow

try {
    Start-Process $localPath
    Write-Host "  File opened: $filename" -ForegroundColor Green
} catch {
    Write-Host "  Could not open file automatically" -ForegroundColor Yellow
    Write-Host "  Please open manually: $localPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VERIFICATION CHECKLIST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please verify the following in Microsoft Word:" -ForegroundColor White
Write-Host "  [✓] Words have consistent single-space separation" -ForegroundColor Gray
Write-Host "  [✓] No words appear joined or too close together" -ForegroundColor Gray
Write-Host "  [✓] Marathi (Devanagari) text has proper spacing" -ForegroundColor Gray
Write-Host "  [✓] English text has proper spacing" -ForegroundColor Gray
Write-Host "  [✓] Font is 'Noto Sans Devanagari'" -ForegroundColor Gray
Write-Host "  [✓] Page size is A4 (210mm × 297mm)" -ForegroundColor Gray
Write-Host "  [✓] Margins are 25mm on all sides" -ForegroundColor Gray
Write-Host "  [✓] Line spacing is 1.5" -ForegroundColor Gray
Write-Host ""
Write-Host "File location: $localPath" -ForegroundColor Cyan
Write-Host ""

