# Build script with corrected JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-22"
Set-Location "C:\Users\oshan\Desktop\DTP\ScanDoc"
.\gradlew.bat clean assembleDebug

