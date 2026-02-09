@echo off
REM ============================================================================
REM ScanDoc - Quick Install Script (Batch Wrapper)
REM ============================================================================
REM This batch file runs the PowerShell automation script
REM ============================================================================

echo.
echo ============================================================================
echo   ScanDoc - Quick Install Script
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
echo Running automated installation script...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0auto-build-install.ps1" -LaunchApp

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================================================
    echo   Installation failed! Check the error messages above.
    echo ============================================================================
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo   Installation complete!
echo ============================================================================
pause

