# ============================================================================
# ScanDoc - Automated Build & Installation Script for Windows
# ============================================================================
# This script will:
# 1. Check prerequisites (Java, Android SDK, ADB)
# 2. Install missing tools automatically
# 3. Build the app
# 4. Install on connected Android device
# 5. Launch the app and monitor logs
# ============================================================================

param(
    [switch]$SkipPrerequisites,
    [switch]$CleanBuild,
    [switch]$InstallOnly,
    [switch]$LaunchApp
)

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "============================================================================"
Write-Info "  ScanDoc - Automated Build & Installation Script"
Write-Info "============================================================================"
Write-Host ""

# ============================================================================
# STEP 1: CHECK PREREQUISITES
# ============================================================================

if (-not $SkipPrerequisites) {
    Write-Info "[1/8] Checking prerequisites..."
    
    # Check Java
    Write-Info "  → Checking Java installation..."
    try {
        $javaVersion = java -version 2>&1 | Select-String "version" | Select-Object -First 1
        Write-Success "    ✓ Java found: $javaVersion"
    } catch {
        Write-Error "    ✗ Java not found!"
        Write-Warning "    Please install Java 11+ from: https://adoptium.net/"
        exit 1
    }
    
    # Check Android SDK
    Write-Info "  → Checking Android SDK..."
    $androidHome = $env:ANDROID_HOME
    if (-not $androidHome) {
        $androidHome = "$env:LOCALAPPDATA\Android\Sdk"
    }
    
    if (Test-Path $androidHome) {
        Write-Success "    ✓ Android SDK found: $androidHome"
        $env:ANDROID_HOME = $androidHome
    } else {
        Write-Warning "    ⚠ Android SDK not found at standard location"
        Write-Info "    Searching for Android SDK..."
        
        # Common Android SDK locations
        $possiblePaths = @(
            "$env:LOCALAPPDATA\Android\Sdk",
            "$env:ProgramFiles\Android\android-sdk",
            "$env:ProgramFiles(x86)\Android\android-sdk",
            "C:\Android\Sdk"
        )
        
        $found = $false
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                Write-Success "    ✓ Found Android SDK at: $path"
                $env:ANDROID_HOME = $path
                $androidHome = $path
                $found = $true
                break
            }
        }
        
        if (-not $found) {
            Write-Error "    ✗ Android SDK not found!"
            Write-Warning "    Please install Android Studio or Android Command Line Tools"
            Write-Warning "    Download from: https://developer.android.com/studio"
            exit 1
        }
    }
    
    # Check ADB
    Write-Info "  → Checking ADB (Android Debug Bridge)..."
    $adbPath = "$androidHome\platform-tools\adb.exe"
    
    if (Test-Path $adbPath) {
        Write-Success "    ✓ ADB found: $adbPath"
        $env:PATH = "$androidHome\platform-tools;$env:PATH"
    } else {
        Write-Error "    ✗ ADB not found!"
        Write-Warning "    Please install Android SDK Platform-Tools"
        Write-Warning "    Run Android Studio → SDK Manager → Install Platform-Tools"
        exit 1
    }
    
    Write-Success "[1/8] Prerequisites check complete!"
    Write-Host ""
}

# ============================================================================
# STEP 2: CHECK DEVICE CONNECTION
# ============================================================================

Write-Info "[2/8] Checking device connection..."

& "$androidHome\platform-tools\adb.exe" start-server | Out-Null
Start-Sleep -Seconds 2

$devices = & "$androidHome\platform-tools\adb.exe" devices | Select-String "device$"

if ($devices.Count -eq 0) {
    Write-Error "  ✗ No Android device connected!"
    Write-Warning ""
    Write-Warning "  Please connect your Android phone via USB and:"
    Write-Warning "  1. Enable Developer Options (tap Build Number 7 times)"
    Write-Warning "  2. Enable USB Debugging in Developer Options"
    Write-Warning "  3. Approve USB debugging prompt on your phone"
    Write-Warning ""
    Write-Info "  Waiting for device connection (press Ctrl+C to cancel)..."
    
    & "$androidHome\platform-tools\adb.exe" wait-for-device
    Write-Success "  ✓ Device connected!"
} else {
    Write-Success "  ✓ Device connected: $($devices[0])"
}

Write-Host ""

# ============================================================================
# STEP 3: GET DEVICE INFO
# ============================================================================

Write-Info "[3/8] Getting device information..."

$deviceModel = & "$androidHome\platform-tools\adb.exe" shell getprop ro.product.model
$androidVersion = & "$androidHome\platform-tools\adb.exe" shell getprop ro.build.version.release
$sdkVersion = & "$androidHome\platform-tools\adb.exe" shell getprop ro.build.version.sdk

Write-Info "  → Device Model: $deviceModel"
Write-Info "  → Android Version: $androidVersion (API $sdkVersion)"

if ([int]$sdkVersion -lt 26) {
    Write-Error "  ✗ Android version too old! Minimum required: Android 8.0 (API 26)"
    exit 1
}

Write-Success "[3/8] Device information retrieved!"
Write-Host ""

# ============================================================================
# STEP 4: BUILD THE APP
# ============================================================================

if (-not $InstallOnly) {
    Write-Info "[4/8] Building ScanDoc app..."
    
    # Navigate to project directory
    $projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $projectDir
    
    Write-Info "  → Project directory: $projectDir"
    
    # Clean build if requested
    if ($CleanBuild) {
        Write-Info "  → Running clean build..."
        & .\gradlew.bat clean
        if ($LASTEXITCODE -ne 0) {
            Write-Error "  ✗ Clean failed!"
            exit 1
        }
    }
    
    # Build debug APK
    Write-Info "  → Building debug APK (this may take a few minutes)..."
    & .\gradlew.bat assembleDebug
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "  ✗ Build failed!"
        exit 1
    }
    
    Write-Success "[4/8] Build complete!"
    Write-Host ""
} else {
    Write-Info "[4/8] Skipping build (InstallOnly mode)"
    Write-Host ""
}

# ============================================================================
# STEP 5: LOCATE APK
# ============================================================================

Write-Info "[5/8] Locating APK file..."

$apkPath = "app\build\outputs\apk\debug\app-debug.apk"

if (-not (Test-Path $apkPath)) {
    Write-Error "  ✗ APK not found at: $apkPath"
    Write-Warning "  Please run build first or check build output"
    exit 1
}

$apkSize = (Get-Item $apkPath).Length / 1MB
Write-Success "  ✓ APK found: $apkPath ($([math]::Round($apkSize, 2)) MB)"
Write-Host ""

# ============================================================================
# STEP 6: INSTALL APK
# ============================================================================

Write-Info "[6/8] Installing ScanDoc on device..."

Write-Info "  → Uninstalling previous version (if exists)..."
& "$androidHome\platform-tools\adb.exe" uninstall com.mk.scandoc 2>&1 | Out-Null

Write-Info "  → Installing APK..."
$installOutput = & "$androidHome\platform-tools\adb.exe" install -r $apkPath 2>&1

if ($installOutput -match "Success") {
    Write-Success "  ✓ Installation successful!"
} else {
    Write-Error "  ✗ Installation failed!"
    Write-Error "  Error: $installOutput"
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 7: VERIFY TRAINEDDATA FILES
# ============================================================================

Write-Info "[7/8] Verifying Tesseract traineddata files..."

Start-Sleep -Seconds 2

Write-Info "  → Checking tessdata folder..."
$tessDataCheck = & "$androidHome\platform-tools\adb.exe" shell "run-as com.mk.scandoc ls /data/data/com.mk.scandoc/files/tessdata/ 2>&1"

if ($tessDataCheck -match "eng.traineddata" -and $tessDataCheck -match "mar.traineddata") {
    Write-Success "  ✓ Traineddata files found:"
    Write-Success "    - eng.traineddata (English)"
    Write-Success "    - mar.traineddata (Marathi)"
} else {
    Write-Warning "  ⚠ Traineddata files not found yet"
    Write-Info "  Files will be copied on first app launch"
}

Write-Host ""

# ============================================================================
# STEP 8: LAUNCH APP & MONITOR
# ============================================================================

Write-Info "[8/8] Launching ScanDoc app..."

if ($LaunchApp) {
    # Clear logcat
    & "$androidHome\platform-tools\adb.exe" logcat -c

    # Launch app
    & "$androidHome\platform-tools\adb.exe" shell am start -n com.mk.scandoc/.MainActivity

    Write-Success "  ✓ App launched!"
    Write-Host ""

    Write-Info "============================================================================"
    Write-Info "  Monitoring app logs (press Ctrl+C to stop)..."
    Write-Info "============================================================================"
    Write-Host ""

    # Monitor logs
    & "$androidHome\platform-tools\adb.exe" logcat | Select-String -Pattern "scandoc|Tesseract|PagesFragment"
} else {
    Write-Success "  ✓ Installation complete!"
    Write-Host ""
    Write-Info "============================================================================"
    Write-Info "  Next Steps:"
    Write-Info "============================================================================"
    Write-Info "  1. Open ScanDoc app on your phone"
    Write-Info "  2. Wait for 'Tesseract ready for OCR' toast message"
    Write-Info "  3. Go to Scan tab and scan a Marathi document"
    Write-Info "  4. Go to Pages tab and click 'Run OCR'"
    Write-Info "  5. Export to DOCX or TXT to verify Marathi text"
    Write-Host ""
    Write-Info "  To monitor logs, run:"
    Write-Info "  adb logcat | Select-String 'scandoc|Tesseract'"
    Write-Host ""
}

Write-Success "============================================================================"
Write-Success "  ScanDoc installation complete! 🎉"
Write-Success "============================================================================"

