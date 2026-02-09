# Rebuild with tessdata_fast files

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Rebuild with tessdata_fast" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectDir = "C:\Users\oshan\Desktop\DTP\ScanDoc"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Set JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"

Write-Host "[1/6] Cleaning..." -ForegroundColor Yellow
Set-Location $projectDir
& .\gradlew.bat clean | Out-Null
Write-Host "[OK] Clean complete" -ForegroundColor Green

Write-Host "[2/6] Building APK..." -ForegroundColor Yellow
& .\gradlew.bat assembleDebug 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    exit 1
}

$apkPath = "$projectDir\app\build\outputs\apk\debug\app-debug.apk"
$apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
Write-Host "[OK] APK built: $apkSize MB" -ForegroundColor Green

Write-Host "[3/6] Uninstalling old app..." -ForegroundColor Yellow
& $adb uninstall com.mk.scandoc 2>&1 | Out-Null
Start-Sleep -Seconds 2
Write-Host "[OK] Uninstalled" -ForegroundColor Green

Write-Host "[4/6] Installing new APK..." -ForegroundColor Yellow
$installOutput = & $adb install $apkPath 2>&1

if ($installOutput -match "Success") {
    Write-Host "[OK] Installed" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Install failed!" -ForegroundColor Red
    exit 1
}

Write-Host "[5/6] Launching app..." -ForegroundColor Yellow
& $adb logcat -c
& $adb shell am start -n com.mk.scandoc/.MainActivity | Out-Null
Start-Sleep -Seconds 5
Write-Host "[OK] Launched" -ForegroundColor Green

Write-Host "[6/6] Checking initialization..." -ForegroundColor Yellow
$logs = & $adb logcat -d -s "MainActivity:*" "TesseractHelper:*"

if ($logs -match "SUCCESS.*Tesseract traineddata files are ready") {
    Write-Host "[SUCCESS] Files initialized!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Traineddata files:" -ForegroundColor Cyan
    $logs | Select-String -Pattern "mar\.traineddata.*bytes|eng\.traineddata.*bytes" | Select-Object -Last 2 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "[ERROR] Initialization failed!" -ForegroundColor Red
    $logs | Select-String -Pattern "ERROR|FATAL" | Select-Object -Last 5 | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

