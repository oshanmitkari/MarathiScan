# Script to rebuild APK with corrected file size validation

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Rebuild with Validation Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Fix Applied:" -ForegroundColor Green
Write-Host "  - Updated TesseractHelper.java: MIN_MAR_SIZE = 2MB (was 10MB)" -ForegroundColor Green
Write-Host "  - Updated PagesFragment.java: MIN_MAR_SIZE = 2MB (was 10MB)" -ForegroundColor Green
Write-Host "  - This allows the 3.05MB mar.traineddata (tessdata) to pass validation" -ForegroundColor Green
Write-Host ""

$projectDir = "C:\Users\oshan\Desktop\DTP\ScanDoc"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$gradlew = "$projectDir\gradlew.bat"

# Fix JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"

# Step 1: Clean build
Write-Host "[1/7] Cleaning previous build..." -ForegroundColor Yellow
Set-Location $projectDir
& $gradlew clean | Out-Null
Write-Host "[OK] Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Build APK
Write-Host "[2/7] Building APK with validation fix..." -ForegroundColor Yellow
$buildOutput = & $gradlew assembleDebug 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    Write-Host $buildOutput
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
Write-Host "[3/7] Verifying traineddata files in APK..." -ForegroundColor Yellow

$tempDir = "$env:TEMP\scandoc_apk_verify_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($apkPath, $tempDir)

$marFile = Get-Item "$tempDir\assets\tessdata\mar.traineddata" -ErrorAction SilentlyContinue
$engFile = Get-Item "$tempDir\assets\tessdata\eng.traineddata" -ErrorAction SilentlyContinue

if ($marFile) {
    $marSizeMB = [math]::Round($marFile.Length / 1MB, 2)
    Write-Host "  mar.traineddata: $marSizeMB MB ($($marFile.Length) bytes)" -ForegroundColor Green
    
    if ($marFile.Length -lt 2097152) {
        Write-Host "  [WARNING] mar.traineddata is smaller than 2MB!" -ForegroundColor Red
        Remove-Item $tempDir -Recurse -Force
        exit 1
    }
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
Write-Host "[4/7] Uninstalling old app..." -ForegroundColor Yellow
& $adb uninstall com.mk.scandoc 2>&1 | Out-Null
Start-Sleep -Seconds 2
Write-Host "[OK] Old app uninstalled" -ForegroundColor Green
Write-Host ""

# Step 5: Install new APK
Write-Host "[5/7] Installing new APK..." -ForegroundColor Yellow
$installOutput = & $adb install $apkPath 2>&1

if ($installOutput -match "Success") {
    Write-Host "[OK] APK installed successfully" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Installation failed:" -ForegroundColor Red
    Write-Host $installOutput
    exit 1
}
Write-Host ""

# Step 6: Launch app
Write-Host "[6/7] Launching app..." -ForegroundColor Yellow
& $adb logcat -c
Start-Sleep -Seconds 1
& $adb shell am start -n com.mk.scandoc/.MainActivity
Start-Sleep -Seconds 4

Write-Host "[OK] App launched" -ForegroundColor Green
Write-Host ""

# Step 7: Check initialization logs
Write-Host "[7/7] Checking initialization logs..." -ForegroundColor Yellow
Write-Host ""

$initLogs = & $adb logcat -d -s "MainActivity:*" "TesseractHelper:*" "PagesFragment:*"

# Check for success
if ($initLogs -match "All required files copied and verified") {
    Write-Host "[SUCCESS] Traineddata files copied successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Could not confirm file copy success" -ForegroundColor Yellow
}

# Display relevant logs
Write-Host ""
Write-Host "Initialization logs:" -ForegroundColor Cyan
$initLogs | Select-String -Pattern "traineddata|mar\.traineddata|eng\.traineddata|copied|verified|ERROR|FAIL" | ForEach-Object { Write-Host $_.Line }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The app has been installed with corrected file size validation." -ForegroundColor Green
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "  - mar.traineddata minimum size: 10MB -> 2MB" -ForegroundColor Yellow
Write-Host "  - This allows the 3.05MB tessdata file to pass validation" -ForegroundColor Yellow
Write-Host ""

