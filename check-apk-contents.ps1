$apk = "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_FIXED.apk"
$tempDir = "C:\Users\oshan\Desktop\temp_apk_check"

if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}

New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "Extracting APK..." -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($apk, $tempDir)

Write-Host "Checking for traineddata files in APK..." -ForegroundColor Yellow
$marFile = Join-Path $tempDir "assets\tessdata\mar.traineddata"
$engFile = Join-Path $tempDir "assets\tessdata\eng.traineddata"

if (Test-Path $marFile) {
    $marSize = (Get-Item $marFile).Length
    Write-Host "  mar.traineddata: $marSize bytes" -ForegroundColor $(if ($marSize -gt 10485760) { "Green" } else { "Red" })
} else {
    Write-Host "  mar.traineddata: NOT FOUND!" -ForegroundColor Red
}

if (Test-Path $engFile) {
    $engSize = (Get-Item $engFile).Length
    Write-Host "  eng.traineddata: $engSize bytes" -ForegroundColor $(if ($engSize -gt 4194304) { "Green" } else { "Red" })
} else {
    Write-Host "  eng.traineddata: NOT FOUND!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item $tempDir -Recurse -Force
Write-Host "Done!" -ForegroundColor Green

