@echo off
REM ============================================================================
REM ScanDoc - Crash Log Capture Script
REM ============================================================================
REM This script captures crash logs from your Android device
REM ============================================================================

echo.
echo ============================================================================
echo   ScanDoc - Crash Log Capture
echo ============================================================================
echo.

REM Check if ADB is available
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ADB not found!
    echo.
    echo Trying to use Android SDK ADB...
    set ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
    if not exist "%ADB_PATH%" (
        echo ERROR: Android SDK ADB also not found!
        echo Please install Android SDK or add ADB to PATH.
        pause
        exit /b 1
    )
) else (
    set ADB_PATH=adb
)

echo Using ADB: %ADB_PATH%
echo.

REM Check device connection
echo Checking device connection...
%ADB_PATH% devices
echo.

echo ============================================================================
echo   Instructions:
echo ============================================================================
echo   1. Keep this window open
echo   2. On your phone, tap the ScanDoc app icon
echo   3. Wait for the crash to happen
echo   4. Press Ctrl+C to stop log capture
echo.
echo   Logs will be saved to: crash_logs.txt
echo ============================================================================
echo.

REM Clear old logs
%ADB_PATH% logcat -c

echo Starting log capture...
echo.

REM Capture logs and save to file
%ADB_PATH% logcat -v time *:E | tee crash_logs.txt

pause

