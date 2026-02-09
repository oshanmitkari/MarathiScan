# Script to download Tesseract 4.x compatible traineddata files

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Download Compatible Traineddata Files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] The current mar.traineddata is from tessdata_best (Tesseract 5.x)" -ForegroundColor Yellow
Write-Host "[INFO] tess-two 9.1.0 uses Tesseract 4.x, which requires tessdata (not tessdata_best)" -ForegroundColor Yellow
Write-Host ""

$assetDir = "C:\Users\oshan\Desktop\DTP\ScanDoc\app\src\main\assets\tessdata"

# Backup current files
Write-Host "Creating backup of current traineddata files..." -ForegroundColor Yellow
$backupDir = "C:\Users\oshan\Desktop\DTP\ScanDoc\traineddata_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item "$assetDir\*.traineddata" $backupDir -Force
Write-Host "[OK] Backup created at: $backupDir" -ForegroundColor Green
Write-Host ""

# Download mar.traineddata from tessdata (Tesseract 4.x compatible)
Write-Host "Downloading mar.traineddata from tessdata repository (Tesseract 4.x compatible)..." -ForegroundColor Yellow
$marUrl = "https://github.com/tesseract-ocr/tessdata/raw/main/mar.traineddata"
$marPath = "$assetDir\mar.traineddata"

try {
    Invoke-WebRequest -Uri $marUrl -OutFile $marPath -UseBasicParsing
    $marSize = (Get-Item $marPath).Length
    $marSizeMB = [math]::Round($marSize / 1MB, 2)
    Write-Host "[OK] Downloaded mar.traineddata: $marSizeMB MB ($marSize bytes)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to download mar.traineddata: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Download eng.traineddata from tessdata (Tesseract 4.x compatible)
Write-Host "Downloading eng.traineddata from tessdata repository (Tesseract 4.x compatible)..." -ForegroundColor Yellow
$engUrl = "https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata"
$engPath = "$assetDir\eng.traineddata"

try {
    Invoke-WebRequest -Uri $engUrl -OutFile $engPath -UseBasicParsing
    $engSize = (Get-Item $engPath).Length
    $engSizeMB = [math]::Round($engSize / 1MB, 2)
    Write-Host "[OK] Downloaded eng.traineddata: $engSizeMB MB ($engSize bytes)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to download eng.traineddata: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Download Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Green
Write-Host "  - mar.traineddata: $marSizeMB MB (tessdata - Tesseract 4.x compatible)" -ForegroundColor Green
Write-Host "  - eng.traineddata: $engSizeMB MB (tessdata - Tesseract 4.x compatible)" -ForegroundColor Green
Write-Host "  - Backup location: $backupDir" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Rebuild the APK with the new traineddata files" -ForegroundColor Yellow
Write-Host "  2. Reinstall the app on your device" -ForegroundColor Yellow
Write-Host "  3. Test OCR functionality" -ForegroundColor Yellow
Write-Host ""

