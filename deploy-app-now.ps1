# Auto Rebuild, Uninstall, Install, and Run ScanDoc App
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AUTO REBUILD & DEPLOY SCANDOC APP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set paths
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$projectDir = "C:\Users\oshan\Desktop\DTP\ScanDoc"
$packageName = "com.mk.scandoc"
$apkPath = "$projectDir\app\build\outputs\apk\debug\app-debug.apk"
$logFile = "C:\Users\oshan\Desktop\scandoc_auto_deploy.txt"

# Check if ADB exists
if (-not (Test-Path $adb)) {
    Write-Host "[ERROR] ADB not found" -ForegroundColor Red
    exit 1
}

# Check if device is connected
Write-Host "[1/6] Checking device connection..." -ForegroundColor Yellow
$devices = & $adb devices
if ($devices -match "device$") {
    Write-Host "  Device connected" -ForegroundColor Green
} else {
    Write-Host "  No device connected!" -ForegroundColor Red
    exit 1
}

# Uninstall old app
Write-Host ""
Write-Host "[2/6] Uninstalling old app..." -ForegroundColor Yellow
$uninstallResult = & $adb uninstall $packageName 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Old app uninstalled" -ForegroundColor Green
} else {
    Write-Host "  App not installed (OK if first install)" -ForegroundColor Yellow
}

# Clean build
Write-Host ""
Write-Host "[3/6] Cleaning previous build..." -ForegroundColor Yellow
Set-Location $projectDir
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"
& .\gradlew.bat clean | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Clean successful" -ForegroundColor Green
} else {
    Write-Host "  Clean failed!" -ForegroundColor Red
    exit 1
}

# Build APK
Write-Host ""
Write-Host "[4/6] Building APK (this may take 1-2 minutes)..." -ForegroundColor Yellow
$buildOutput = & .\gradlew.bat assembleDebug 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Build successful" -ForegroundColor Green
    
    if (Test-Path $apkPath) {
        $apkSize = (Get-Item $apkPath).Length / 1MB
        Write-Host "  APK created: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Green
    } else {
        Write-Host "  APK not found!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  Build failed!" -ForegroundColor Red
    $buildOutput | Select-String -Pattern "error|ERROR|FAILURE" | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

# Install APK
Write-Host ""
Write-Host "[5/6] Installing APK on device..." -ForegroundColor Yellow
$installResult = & $adb install -r $apkPath 2>&1
if ($LASTEXITCODE -eq 0 -or $installResult -match "Success") {
    Write-Host "  APK installed successfully" -ForegroundColor Green
} else {
    Write-Host "  Installation failed!" -ForegroundColor Red
    Write-Host "  Error: $installResult" -ForegroundColor Red
    exit 1
}

# Launch app
Write-Host ""
Write-Host "[6/6] Launching app..." -ForegroundColor Yellow
& $adb logcat -c
$launchResult = & $adb shell am start -n "$packageName/.MainActivity" 2>&1
if ($launchResult -match "Starting") {
    Write-Host "  App launched successfully" -ForegroundColor Green
} else {
    Write-Host "  Failed to launch app!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting 3 seconds for app to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Capture logs
Write-Host ""
Write-Host "Capturing logs..." -ForegroundColor Cyan
$logJob = Start-Job -ScriptBlock {
    param($adbPath, $logPath)
    & $adbPath logcat -d > $logPath
} -ArgumentList $adb, $logFile

Wait-Job $logJob -Timeout 10 | Out-Null
Stop-Job $logJob -ErrorAction SilentlyContinue
Remove-Job $logJob -ErrorAction SilentlyContinue

# Display logs
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  KEY LOGS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path $logFile) {
    $logs = Get-Content $logFile
    $relevantLogs = $logs | Select-String -Pattern "TesseractHelper|MainActivity|tessdata|traineddata" | Select-Object -Last 50
    
    if ($relevantLogs) {
        $relevantLogs | ForEach-Object {
            $line = $_.Line
            if ($line -match "ERROR|FATAL") {
                Write-Host $line -ForegroundColor Red
            } elseif ($line -match "SUCCESS|OK") {
                Write-Host $line -ForegroundColor Green
            } else {
                Write-Host $line -ForegroundColor White
            }
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "App is running on your phone!" -ForegroundColor Cyan
Write-Host "Navigate to Pages tab and click Run OCR to test" -ForegroundColor White
Write-Host ""

