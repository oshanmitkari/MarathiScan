# Script to rebuild APK with compatible traineddata and reinstall

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Rebuild and Reinstall ScanDoc" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectDir = "C:\Users\oshan\Desktop\DTP\ScanDoc"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$gradlew = "$projectDir\gradlew.bat"

# Fix JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"
Write-Host "JAVA_HOME set to: $env:JAVA_HOME" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean build
Write-Host "[1/6] Cleaning previous build..." -ForegroundColor Yellow
Set-Location $projectDir
& $gradlew clean
Write-Host "[OK] Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Build APK
Write-Host "[2/6] Building APK with compatible traineddata files..." -ForegroundColor Yellow
& $gradlew assembleDebug

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    exit 1
}

$apkPath = "$projectDir\app\build\outputs\apk\debug\app-debug.apk"

if (-not (Test-Path $apkPath)) {
    Write-Host "[ERROR] APK not found at: $apkPath" -ForegroundColor Red
    exit 1
}

$apkSize = (Get-Item $apkPath).Length
$apkSizeMB = [math]::Round($apkSize / 1MB, 2)
Write-Host "[OK] APK built successfully: $apkSizeMB MB" -ForegroundColor Green
Write-Host ""

# Step 3: Verify APK contents
Write-Host "[3/6] Verifying traineddata files in APK..." -ForegroundColor Yellow

$tempDir = "$env:TEMP\scandoc_apk_verify_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($apkPath, $tempDir)

$marFile = Get-Item "$tempDir\assets\tessdata\mar.traineddata" -ErrorAction SilentlyContinue
$engFile = Get-Item "$tempDir\assets\tessdata\eng.traineddata" -ErrorAction SilentlyContinue

if ($marFile) {
    $marSizeMB = [math]::Round($marFile.Length / 1MB, 2)
    Write-Host "  mar.traineddata: $marSizeMB MB ($($marFile.Length) bytes)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] mar.traineddata NOT found in APK!" -ForegroundColor Red
    Remove-Item $tempDir -Recurse -Force
    exit 1
}

if ($engFile) {
    $engSizeMB = [math]::Round($engFile.Length / 1MB, 2)
    Write-Host "  eng.traineddata: $engSizeMB MB ($($engFile.Length) bytes)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] eng.traineddata NOT found in APK!" -ForegroundColor Red
    Remove-Item $tempDir -Recurse -Force
    exit 1
}

Remove-Item $tempDir -Recurse -Force
Write-Host "[OK] Traineddata files verified" -ForegroundColor Green
Write-Host ""

# Step 4: Uninstall old app
Write-Host "[4/6] Uninstalling old app..." -ForegroundColor Yellow
& $adb uninstall com.mk.scandoc 2>&1 | Out-Null
Start-Sleep -Seconds 2
Write-Host "[OK] Old app uninstalled" -ForegroundColor Green
Write-Host ""

# Step 5: Install new APK
Write-Host "[5/6] Installing new APK..." -ForegroundColor Yellow
$installOutput = & $adb install $apkPath 2>&1

if ($installOutput -match "Success") {
    Write-Host "[OK] APK installed successfully" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Installation failed:" -ForegroundColor Red
    Write-Host $installOutput
    exit 1
}
Write-Host ""

# Step 6: Launch app and monitor logs
Write-Host "[6/6] Launching app and monitoring initialization..." -ForegroundColor Yellow
Write-Host ""

& $adb logcat -c
Start-Sleep -Seconds 1

& $adb shell am start -n com.mk.scandoc/.MainActivity
Start-Sleep -Seconds 3

Write-Host "App initialization logs:" -ForegroundColor Cyan
& $adb logcat -d -s "MainActivity:*" "TesseractHelper:*" "PagesFragment:*"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The app has been installed with Tesseract 4.x compatible traineddata files." -ForegroundColor Green
Write-Host ""
Write-Host "Please test the OCR functionality:" -ForegroundColor Yellow
Write-Host "  1. Add a page with Marathi/English text" -ForegroundColor Yellow
Write-Host "  2. Navigate to Pages tab" -ForegroundColor Yellow
Write-Host "  3. Click 'Run OCR'" -ForegroundColor Yellow
Write-Host "  4. Verify that the app does NOT crash" -ForegroundColor Yellow
Write-Host ""

