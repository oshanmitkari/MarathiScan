# ============================================================================
# ScanDoc - Standalone APK Builder (No Device Required)
# ============================================================================
# This script builds the APK without requiring a connected Android device
# Perfect for building APK to transfer manually via email, cloud, USB, etc.
# ============================================================================

param(
    [switch]$CleanBuild,
    [switch]$Release,
    [string]$OutputFolder = "$env:USERPROFILE\Desktop\ScanDoc_APK"
)

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "============================================================================"
Write-Info "  ScanDoc - Standalone APK Builder"
Write-Info "  (No device connection required)"
Write-Info "============================================================================"
Write-Host ""

# ============================================================================
# STEP 1: CHECK JAVA
# ============================================================================

Write-Info "[1/5] Checking Java installation..."

try {
    $javaVersion = java -version 2>&1 | Select-String "version" | Select-Object -First 1
    Write-Success "  [OK] Java found: $javaVersion"
} catch {
    Write-Error "  [ERROR] Java not found!"
    Write-Warning "  Please install Java 11+ from: https://adoptium.net/"
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 2: NAVIGATE TO PROJECT
# ============================================================================

Write-Info "[2/5] Locating project directory..."

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

Write-Success "  [OK] Project directory: $projectDir"
Write-Host ""

# ============================================================================
# STEP 3: BUILD APK
# ============================================================================

Write-Info "[3/5] Building APK..."

# Clean build if requested
if ($CleanBuild) {
    Write-Info "  -> Running clean build..."
    & .\gradlew.bat clean
    if ($LASTEXITCODE -ne 0) {
        Write-Error "  [ERROR] Clean failed!"
        exit 1
    }
    Write-Success "  [OK] Clean complete"
}

# Determine build type
$buildType = if ($Release) { "Release" } else { "Debug" }
$buildTask = if ($Release) { "assembleRelease" } else { "assembleDebug" }

Write-Info "  -> Building $buildType APK..."
Write-Info "  -> This may take 3-5 minutes on first run (downloading dependencies)..."
Write-Info "  -> Subsequent builds will be faster (30-60 seconds)..."
Write-Host ""

# Build APK
& .\gradlew.bat $buildTask

if ($LASTEXITCODE -ne 0) {
    Write-Error "  [ERROR] Build failed!"
    Write-Warning ""
    Write-Warning "  Common solutions:"
    Write-Warning "  1. Run with -CleanBuild flag: .\build-apk-only.ps1 -CleanBuild"
    Write-Warning "  2. Check internet connection (for dependency download)"
    Write-Warning "  3. Ensure Java 11+ is installed"
    exit 1
}

Write-Success "  [OK] Build complete!"
Write-Host ""

# ============================================================================
# STEP 4: LOCATE APK
# ============================================================================

Write-Info "[4/5] Locating APK file..."

$apkSubPath = if ($Release) { "release\app-release-unsigned.apk" } else { "debug\app-debug.apk" }
$apkPath = "app\build\outputs\apk\$apkSubPath"

if (-not (Test-Path $apkPath)) {
    Write-Error "  [ERROR] APK not found at: $apkPath"
    exit 1
}

$apkSize = (Get-Item $apkPath).Length / 1MB
$apkFullPath = (Resolve-Path $apkPath).Path

Write-Success "  [OK] APK found!"
Write-Info "  -> Location: $apkFullPath"
Write-Info "  -> Size: $([math]::Round($apkSize, 2)) MB"
Write-Host ""

# ============================================================================
# STEP 5: COPY TO OUTPUT FOLDER
# ============================================================================

Write-Info "[5/5] Copying APK to easy-access location..."

# Create output folder
New-Item -ItemType Directory -Force -Path $OutputFolder | Out-Null

# Generate filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFileName = "ScanDoc_$buildType`_$timestamp.apk"
$outputPath = Join-Path $OutputFolder $outputFileName

# Copy APK
Copy-Item -Path $apkPath -Destination $outputPath -Force

Write-Success "  [OK] APK copied to: $outputPath"
Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Success "============================================================================"
Write-Success "  APK Build Complete!"
Write-Success "============================================================================"
Write-Host ""
Write-Info "APK Details:"
Write-Info "  -> Build Type: $buildType"
Write-Info "  -> Size: $([math]::Round($apkSize, 2)) MB"
Write-Info "  -> Package: com.mk.scandoc"
Write-Host ""
Write-Info "APK Locations:"
Write-Info ""
Write-Info "  1. Build Output (original):"
Write-Info "     $apkFullPath"
Write-Info ""
Write-Info "  2. Easy Access Copy:"
Write-Info "     $outputPath"
Write-Host ""
Write-Info "How to Install on Your Phone:"
Write-Host ""
Write-Info "  Option 1: USB Transfer"
Write-Info "  ----------------------"
Write-Info "  1. Connect phone via USB"
Write-Info "  2. Copy APK to phone's Download folder"
Write-Info "  3. Open File Manager on phone"
Write-Info "  4. Tap the APK file"
Write-Info "  5. Tap 'Install'"
Write-Host ""
Write-Info "  Option 2: Cloud Storage"
Write-Info "  -----------------------"
Write-Info "  1. Upload APK to Google Drive / Dropbox / OneDrive"
Write-Info "  2. Open link on phone"
Write-Info "  3. Download APK"
Write-Info "  4. Tap downloaded file to install"
Write-Host ""
Write-Info "  Option 3: Email"
Write-Info "  ---------------"
Write-Info "  1. Email APK to yourself"
Write-Info "  2. Open email on phone"
Write-Info "  3. Download attachment"
Write-Info "  4. Tap to install"
Write-Host ""
Write-Info "  Option 4: ADB (if phone connected later)"
Write-Info "  -----------------------------------------"
Write-Info "  adb install -r `"$outputPath`""
Write-Host ""
Write-Warning "Note: You may need to enable 'Install from Unknown Sources' on your phone"
Write-Warning "    Settings -> Security -> Unknown Sources (or Install Unknown Apps)"
Write-Host ""
Write-Success "============================================================================"
Write-Host ""

# Open output folder
Write-Info "Opening output folder..."
Start-Process explorer.exe -ArgumentList $OutputFolder

Write-Success "Done!"
Write-Host ""

