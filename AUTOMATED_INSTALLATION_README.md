# 🤖 Automated Build & Installation Scripts

## 📋 Overview

I've created **3 automated scripts** to build and install ScanDoc on your Android phone with **zero manual steps**:

1. **`quick-install.bat`** - Double-click to run everything automatically ⚡
2. **`auto-build-install.ps1`** - Main PowerShell automation script
3. **`install-android-sdk.ps1`** - Android SDK installer (if needed)

---

## 🚀 Quick Start (Easiest Method)

### **Option 1: Double-Click Installation**

1. **Connect your Android phone via USB**
2. **Enable USB Debugging** (see instructions below if not done)
3. **Double-click `quick-install.bat`**
4. **Wait for completion** (3-5 minutes)
5. **Done!** App will launch automatically

---

### **Option 2: PowerShell Command**

```powershell
# Navigate to project directory
cd C:\Users\oshan\Desktop\DTP\ScanDoc

# Run automated script
powershell -ExecutionPolicy Bypass -File auto-build-install.ps1 -LaunchApp
```

---

## 📱 Enable USB Debugging (One-Time Setup)

If you haven't enabled USB debugging yet:

1. Open **Settings** on your phone
2. Go to **About Phone**
3. Tap **Build Number** 7 times rapidly
4. Go back to **Settings** → **Developer Options**
5. Enable **USB Debugging**
6. Connect phone to PC via USB
7. Approve the **"Allow USB debugging?"** prompt on your phone

---

## 🛠️ What the Scripts Do

### **`auto-build-install.ps1`** (Main Script)

This script automatically:

✅ **Checks prerequisites** (Java, Android SDK, ADB)  
✅ **Detects connected Android device**  
✅ **Gets device information** (model, Android version)  
✅ **Builds the app** using Gradle  
✅ **Uninstalls old version** (if exists)  
✅ **Installs new APK** on your phone  
✅ **Verifies traineddata files** (eng.traineddata, mar.traineddata)  
✅ **Launches the app** (optional)  
✅ **Monitors logs** in real-time (optional)

---

### **Script Parameters**

```powershell
# Build and install with app launch
.\auto-build-install.ps1 -LaunchApp

# Clean build (delete previous build artifacts)
.\auto-build-install.ps1 -CleanBuild -LaunchApp

# Install only (skip build, use existing APK)
.\auto-build-install.ps1 -InstallOnly

# Skip prerequisite checks (faster, for repeated runs)
.\auto-build-install.ps1 -SkipPrerequisites -LaunchApp
```

---

## 🔧 Troubleshooting

### **Issue: "Android SDK not found"**

**Solution:** Run the SDK installer script:

```powershell
powershell -ExecutionPolicy Bypass -File install-android-sdk.ps1
```

Then restart your terminal and run the main script again.

---

### **Issue: "No Android device connected"**

**Solutions:**

1. Check USB cable (use data cable, not charge-only)
2. Try different USB port
3. Enable USB Debugging (see instructions above)
4. Approve USB debugging prompt on phone
5. Install phone manufacturer's USB drivers:
   - Samsung: https://developer.samsung.com/android-usb-driver
   - Xiaomi: https://www.xiaomitool.com/V2/drivers
   - OnePlus: https://www.oneplus.com/support/softwareupgrade

---

### **Issue: "Build failed"**

**Solution:** Run clean build:

```powershell
.\auto-build-install.ps1 -CleanBuild
```

---

### **Issue: "Installation failed"**

**Solution:** Manually uninstall old version:

```powershell
# Uninstall from phone
adb uninstall com.mk.scandoc

# Then run script again
.\auto-build-install.ps1 -InstallOnly
```

---

## 📊 Expected Output

```
============================================================================
  ScanDoc - Automated Build & Installation Script
============================================================================

[1/8] Checking prerequisites...
  → Checking Java installation...
    ✓ Java found: version "22.0.2"
  → Checking Android SDK...
    ✓ Android SDK found: C:\Users\oshan\AppData\Local\Android\Sdk
  → Checking ADB (Android Debug Bridge)...
    ✓ ADB found: C:\Users\oshan\AppData\Local\Android\Sdk\platform-tools\adb.exe
[1/8] Prerequisites check complete!

[2/8] Checking device connection...
  ✓ Device connected: ABC123XYZ    device

[3/8] Getting device information...
  → Device Model: SM-G991B
  → Android Version: 13 (API 33)
[3/8] Device information retrieved!

[4/8] Building ScanDoc app...
  → Project directory: C:\Users\oshan\Desktop\DTP\ScanDoc
  → Building debug APK (this may take a few minutes)...
[4/8] Build complete!

[5/8] Locating APK file...
  ✓ APK found: app\build\outputs\apk\debug\app-debug.apk (8.45 MB)

[6/8] Installing ScanDoc on device...
  → Uninstalling previous version (if exists)...
  → Installing APK...
  ✓ Installation successful!

[7/8] Verifying Tesseract traineddata files...
  → Checking tessdata folder...
  ✓ Traineddata files found:
    - eng.traineddata (English)
    - mar.traineddata (Marathi)

[8/8] Launching ScanDoc app...
  ✓ App launched!

============================================================================
  Monitoring app logs (press Ctrl+C to stop)...
============================================================================

D/PagesFragment: Tesseract data path: /data/user/0/com.mk.scandoc/files
D/PagesFragment: Found traineddata files:
D/PagesFragment:   - eng.traineddata
D/PagesFragment:   - mar.traineddata
D/PagesFragment: ✅ Tesseract initialized successfully

============================================================================
  ScanDoc installation complete! 🎉
============================================================================
```

---

## ⏱️ Estimated Time

| Step | Time |
|------|------|
| Prerequisites check | 5 seconds |
| Device detection | 2 seconds |
| Build (first time) | 3-5 minutes |
| Build (subsequent) | 30-60 seconds |
| Installation | 10 seconds |
| **Total (first run)** | **4-6 minutes** |
| **Total (subsequent)** | **1-2 minutes** |

---

## 🎯 Next Steps After Installation

Once the script completes:

1. ✅ App is installed and launched on your phone
2. ✅ Wait for **"Tesseract ready for OCR"** toast
3. ✅ Go to **Scan** tab → Scan Marathi document
4. ✅ Go to **Pages** tab → Click **"Run OCR"**
5. ✅ Verify Marathi text displays correctly
6. ✅ Export to **DOCX** and **TXT** to verify

---

## 📚 Additional Documentation

- **`QUICK_START_GUIDE.md`** - 5-minute testing guide
- **`MARATHI_OCR_IMPLEMENTATION.md`** - Complete implementation details
- **`CODE_CHANGES_REFERENCE.md`** - Exact code changes
- **`ANALYSIS_REPORT.md`** - Detailed analysis of fixes

---

## 🆘 Support

If you encounter any issues:

1. Check the error messages in the script output
2. Review the troubleshooting section above
3. Check device logs: `adb logcat | Select-String "scandoc"`
4. Verify USB debugging is enabled
5. Try clean build: `.\auto-build-install.ps1 -CleanBuild`

---

## ✨ Features

- ✅ **Zero manual steps** - Everything automated
- ✅ **Smart detection** - Finds Android SDK automatically
- ✅ **Device validation** - Checks Android version compatibility
- ✅ **Error handling** - Clear error messages and solutions
- ✅ **Progress tracking** - Shows what's happening at each step
- ✅ **Log monitoring** - Real-time app logs (optional)
- ✅ **Flexible options** - Clean build, install-only, skip checks

---

## 🎉 You're Ready!

Just **double-click `quick-install.bat`** and everything will be done automatically!

**Happy Testing! 🚀📱**

