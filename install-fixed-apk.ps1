$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "Uninstalling old app..." -ForegroundColor Yellow
& $adb uninstall com.mk.scandoc

Write-Host "Installing fixed APK..." -ForegroundColor Yellow
& $adb install "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_FIXED.apk"

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Please open the app and test OCR functionality" -ForegroundColor Cyan

