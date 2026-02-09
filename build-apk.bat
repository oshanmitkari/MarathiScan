@echo off
REM ============================================================================
REM ScanDoc - Build APK Only (No Device Required)
REM ============================================================================
REM Double-click this file to build APK without connecting your phone
REM ============================================================================

echo.
echo ============================================================================
echo   ScanDoc - Standalone APK Builder
echo   (No device connection required)
echo ============================================================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found!
    echo Please ensure PowerShell is installed on your system.
    pause
    exit /b 1
)

REM Run PowerShell script with execution policy bypass
echo Building APK...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0build-apk-only.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================================================
    echo   Build failed! Check the error messages above.
    echo ============================================================================
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo   Build complete! APK is ready for transfer.
echo ============================================================================
pause

