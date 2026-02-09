# Script to download tessdata_fast (most compatible) traineddata files

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Download tessdata_fast Files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[ANALYSIS] The app is still crashing with NATIVE CRASH during tessAPI.init()" -ForegroundColor Red
Write-Host ""
Write-Host "Attempted fixes:" -ForegroundColor Yellow
Write-Host "  1. tessdata_best (Tesseract 5.x) - FAILED (native crash)" -ForegroundColor Red
Write-Host "  2. tessdata (Tesseract 4.x) - FAILED (native crash)" -ForegroundColor Red
Write-Host ""
Write-Host "Next attempt:" -ForegroundColor Cyan
Write-Host "  3. tessdata_fast (Tesseract 3.x/4.x compatible, smaller files)" -ForegroundColor Cyan
Write-Host ""
Write-Host "tessdata_fast uses smaller, faster models that are more compatible" -ForegroundColor Yellow
Write-Host "with older Tesseract versions (including tess-two 9.1.0)" -ForegroundColor Yellow
Write-Host ""

$assetDir = "C:\Users\oshan\Desktop\DTP\ScanDoc\app\src\main\assets\tessdata"

# Backup current files
Write-Host "Creating backup of current traineddata files..." -ForegroundColor Yellow
$backupDir = "C:\Users\oshan\Desktop\DTP\ScanDoc\traineddata_backup_tessdata_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item "$assetDir\*.traineddata" $backupDir -Force
Write-Host "[OK] Backup created at: $backupDir" -ForegroundColor Green
Write-Host ""

# Download mar.traineddata from tessdata_fast
Write-Host "Downloading mar.traineddata from tessdata_fast repository..." -ForegroundColor Yellow
$marUrl = "https://github.com/tesseract-ocr/tessdata_fast/raw/main/mar.traineddata"
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

# Download eng.traineddata from tessdata_fast
Write-Host "Downloading eng.traineddata from tessdata_fast repository..." -ForegroundColor Yellow
$engUrl = "https://github.com/tesseract-ocr/tessdata_fast/raw/main/eng.traineddata"
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
Write-Host "  - mar.traineddata: $marSizeMB MB (tessdata_fast - most compatible)" -ForegroundColor Green
Write-Host "  - eng.traineddata: $engSizeMB MB (tessdata_fast - most compatible)" -ForegroundColor Green
Write-Host "  - Backup location: $backupDir" -ForegroundColor Green
Write-Host ""
Write-Host "tessdata_fast characteristics:" -ForegroundColor Cyan
Write-Host "  - Smaller file sizes (faster loading)" -ForegroundColor Cyan
Write-Host "  - Compatible with Tesseract 3.x and 4.x" -ForegroundColor Cyan
Write-Host "  - Lower accuracy than tessdata/tessdata_best" -ForegroundColor Cyan
Write-Host "  - Best compatibility with older tess-two versions" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update file size validation (mar.traineddata will be ~1-2MB)" -ForegroundColor Yellow
Write-Host "  2. Rebuild the APK" -ForegroundColor Yellow
Write-Host "  3. Reinstall and test" -ForegroundColor Yellow
Write-Host ""

