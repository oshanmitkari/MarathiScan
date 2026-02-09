# ============================================================================
# Android SDK Command Line Tools - Automated Installer
# ============================================================================
# This script downloads and installs Android SDK Command Line Tools
# if Android SDK is not already installed
# ============================================================================

param(
    [string]$InstallPath = "$env:LOCALAPPDATA\Android\Sdk"
)

function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "============================================================================"
Write-Info "  Android SDK Command Line Tools - Automated Installer"
Write-Info "============================================================================"
Write-Host ""

# Check if Android SDK already exists
if (Test-Path $InstallPath) {
    Write-Success "Android SDK already installed at: $InstallPath"
    Write-Info "Checking for required components..."
    
    $platformTools = "$InstallPath\platform-tools"
    $buildTools = "$InstallPath\build-tools"
    
    if ((Test-Path $platformTools) -and (Test-Path $buildTools)) {
        Write-Success "✓ All required components found!"
        Write-Info ""
        Write-Info "ANDROID_HOME should be set to: $InstallPath"
        Write-Info ""
        Write-Info "To set environment variable, run as Administrator:"
        Write-Info '[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "' + $InstallPath + '", "User")'
        exit 0
    }
}

Write-Info "Installing Android SDK Command Line Tools..."
Write-Host ""

# Create installation directory
Write-Info "Creating installation directory: $InstallPath"
New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null

# Download URL for Windows Command Line Tools
$downloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$zipFile = "$env:TEMP\android-cmdline-tools.zip"

Write-Info "Downloading Android Command Line Tools..."
Write-Info "URL: $downloadUrl"

try {
    # Download with progress
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    Write-Success "✓ Download complete!"
} catch {
    Write-Error "✗ Download failed: $_"
    exit 1
}

# Extract ZIP
Write-Info "Extracting files..."
try {
    Expand-Archive -Path $zipFile -DestinationPath "$InstallPath\cmdline-tools-temp" -Force
    
    # Move to correct location
    $cmdlineToolsPath = "$InstallPath\cmdline-tools\latest"
    New-Item -ItemType Directory -Force -Path $cmdlineToolsPath | Out-Null
    
    Get-ChildItem "$InstallPath\cmdline-tools-temp\cmdline-tools" | Move-Item -Destination $cmdlineToolsPath -Force
    Remove-Item "$InstallPath\cmdline-tools-temp" -Recurse -Force
    
    Write-Success "✓ Extraction complete!"
} catch {
    Write-Error "✗ Extraction failed: $_"
    exit 1
}

# Clean up
Remove-Item $zipFile -Force

# Install required SDK components
Write-Info "Installing required SDK components..."

$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"

if (Test-Path $sdkmanager) {
    Write-Info "Installing platform-tools..."
    & $sdkmanager "platform-tools" --sdk_root=$InstallPath
    
    Write-Info "Installing build-tools..."
    & $sdkmanager "build-tools;34.0.0" --sdk_root=$InstallPath
    
    Write-Info "Installing platform..."
    & $sdkmanager "platforms;android-34" --sdk_root=$InstallPath
    
    Write-Success "✓ SDK components installed!"
} else {
    Write-Error "✗ sdkmanager not found!"
    exit 1
}

# Set environment variable
Write-Info "Setting ANDROID_HOME environment variable..."
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $InstallPath, "User")
$env:ANDROID_HOME = $InstallPath

Write-Success ""
Write-Success "============================================================================"
Write-Success "  Android SDK installation complete!"
Write-Success "============================================================================"
Write-Success ""
Write-Success "Installation path: $InstallPath"
Write-Success "ANDROID_HOME: $env:ANDROID_HOME"
Write-Success ""
Write-Info "Please restart your terminal/PowerShell for changes to take effect."
Write-Success ""

