# 📦 Standalone APK Builder - No Device Required

## 🎯 Overview

Build the ScanDoc APK **without connecting your Android phone**. Perfect for:

- ✅ Building APK to transfer later via USB
- ✅ Sharing APK via email or cloud storage
- ✅ Building on one computer, installing on phone later
- ✅ Creating backup APK files
- ✅ Testing on multiple devices

---

## 🚀 Quick Start (Easiest Method)

### **Option 1: Double-Click Build**

1. Navigate to: `C:\Users\oshan\Desktop\DTP\ScanDoc`
2. **Double-click: `build-apk.bat`**
3. Wait 3-5 minutes (first time) or 30-60 seconds (subsequent builds)
4. APK will be copied to: `C:\Users\oshan\Desktop\ScanDoc_APK\`
5. Output folder opens automatically

**Done!** APK is ready to transfer to your phone.

---

### **Option 2: PowerShell Command**

```powershell
# Navigate to project
cd C:\Users\oshan\Desktop\DTP\ScanDoc

# Build APK
powershell -ExecutionPolicy Bypass -File build-apk-only.ps1
```

---

## 🛠️ Script Options

### **Clean Build** (recommended if previous build failed)

```powershell
.\build-apk-only.ps1 -CleanBuild
```

Deletes previous build artifacts and rebuilds from scratch.

---

### **Custom Output Folder**

```powershell
# Save to Downloads folder
.\build-apk-only.ps1 -OutputFolder "$env:USERPROFILE\Downloads\ScanDoc"

# Save to USB drive
.\build-apk-only.ps1 -OutputFolder "D:\ScanDoc_APK"
```

---

### **Release Build** (smaller, optimized APK)

```powershell
.\build-apk-only.ps1 -Release
```

**Note:** Release builds are unsigned and need signing for production. Debug builds work fine for testing.

---

## 📊 What the Script Does

The script automatically:

1. ✅ **Checks Java** installation (Java 11+ required)
2. ✅ **Navigates** to project directory
3. ✅ **Builds APK** using Gradle (`gradlew.bat assembleDebug`)
4. ✅ **Locates APK** in build output folder
5. ✅ **Copies APK** to easy-access location with timestamp
6. ✅ **Opens folder** containing the APK
7. ✅ **Shows instructions** for manual installation

**No device connection required!**

---

## 📁 APK Locations

After building, you'll find the APK in **two locations**:

### **1. Original Build Output**
```
C:\Users\oshan\Desktop\DTP\ScanDoc\app\build\outputs\apk\debug\app-debug.apk
```

### **2. Easy Access Copy (with timestamp)**
```
C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_20260131_143022.apk
```

The timestamped copy is easier to find and won't be overwritten by subsequent builds.

---

## 📱 How to Install APK on Your Phone

### **Method 1: USB Transfer (Recommended)**

1. **Connect phone to PC via USB**
2. **Copy APK** from `C:\Users\oshan\Desktop\ScanDoc_APK\` to phone's **Download** folder
3. **On your phone:**
   - Open **File Manager** app
   - Navigate to **Downloads**
   - Tap the **ScanDoc_Debug_*.apk** file
   - Tap **Install**
   - If prompted, enable **"Install from Unknown Sources"** for File Manager
   - Tap **Install** again

---

### **Method 2: Cloud Storage (Google Drive, Dropbox, OneDrive)**

1. **Upload APK** to your cloud storage:
   - Open Google Drive / Dropbox / OneDrive on PC
   - Upload `ScanDoc_Debug_*.apk`
   - Get shareable link (or just access from phone)

2. **On your phone:**
   - Open Google Drive / Dropbox / OneDrive app
   - Find the APK file
   - Tap to download
   - Tap downloaded file to install
   - Enable **"Install from Unknown Sources"** if prompted

---

### **Method 3: Email**

1. **Email APK to yourself:**
   - Compose new email
   - Attach `ScanDoc_Debug_*.apk`
   - Send to your email address

2. **On your phone:**
   - Open email app
   - Open the email with APK attachment
   - Download attachment
   - Tap downloaded file to install

---

### **Method 4: ADB (if you connect phone later)**

```powershell
# Connect phone via USB
# Enable USB Debugging

# Install APK
adb install -r "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_20260131_143022.apk"
```

---

## ⚙️ Enable "Install from Unknown Sources"

Since this APK is not from Google Play Store, you need to allow installation:

### **Android 8.0+ (Oreo and newer)**

1. When you tap the APK to install, you'll see a prompt
2. Tap **Settings**
3. Enable **"Allow from this source"** for File Manager / Chrome / Email app
4. Go back and tap **Install**

### **Android 7.1 and older**

1. Go to **Settings** → **Security**
2. Enable **"Unknown Sources"**
3. Tap **OK** on warning dialog
4. Install the APK

---

## ⏱️ Build Time

| Build Type | First Run | Subsequent Runs |
|------------|-----------|-----------------|
| Debug | 3-5 minutes | 30-60 seconds |
| Clean Build | 4-6 minutes | 1-2 minutes |
| Release | 4-6 minutes | 1-2 minutes |

**First run is slower** because Gradle downloads dependencies (one-time only).

---

## 📊 Expected Output

```
============================================================================
  ScanDoc - Standalone APK Builder
  (No device connection required)
============================================================================

[1/5] Checking Java installation...
  ✓ Java found: version "22.0.2"

[2/5] Locating project directory...
  ✓ Project directory: C:\Users\oshan\Desktop\DTP\ScanDoc

[3/5] Building APK...
  → Building Debug APK...
  → This may take 3-5 minutes on first run (downloading dependencies)...
  → Subsequent builds will be faster (30-60 seconds)...

BUILD SUCCESSFUL in 2m 34s
  ✓ Build complete!

[4/5] Locating APK file...
  ✓ APK found!
  → Location: C:\Users\oshan\Desktop\DTP\ScanDoc\app\build\outputs\apk\debug\app-debug.apk
  → Size: 8.45 MB

[5/5] Copying APK to easy-access location...
  ✓ APK copied to: C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_20260131_143022.apk

============================================================================
  APK Build Complete! 🎉
============================================================================

📦 APK Details:
  → Build Type: Debug
  → Size: 8.45 MB
  → Package: com.mk.scandoc

📁 APK Locations:

  1. Build Output (original):
     C:\Users\oshan\Desktop\DTP\ScanDoc\app\build\outputs\apk\debug\app-debug.apk

  2. Easy Access Copy:
     C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_20260131_143022.apk

📱 How to Install on Your Phone:
  [Installation instructions displayed...]

Opening output folder...

Done! 🚀
```

---

## 🐛 Troubleshooting

### **Issue: "Java not found"**

**Solution:** Install Java 11 or higher

```powershell
# Download from: https://adoptium.net/
# Install and restart terminal
```

---

### **Issue: "Build failed"**

**Solution 1:** Run clean build

```powershell
.\build-apk-only.ps1 -CleanBuild
```

**Solution 2:** Check internet connection (for dependency download)

**Solution 3:** Delete `.gradle` folder and rebuild

```powershell
Remove-Item -Recurse -Force .gradle
.\build-apk-only.ps1
```

---

### **Issue: "APK not found after build"**

**Solution:** Check build output for errors

```powershell
# Run with verbose output
.\gradlew.bat assembleDebug --stacktrace
```

---

### **Issue: "Installation blocked" on phone**

**Solution:** Enable "Install from Unknown Sources" (see instructions above)

---

## 📋 Comparison: Standalone vs Full Automation

| Feature | `build-apk.bat` | `quick-install.bat` |
|---------|-----------------|---------------------|
| Requires phone connected | ❌ No | ✅ Yes |
| Builds APK | ✅ Yes | ✅ Yes |
| Installs on phone | ❌ No (manual) | ✅ Yes (automatic) |
| Launches app | ❌ No | ✅ Yes |
| Monitors logs | ❌ No | ✅ Yes |
| Best for | Building APK to transfer later | Quick test on connected device |

---

## ✨ Use Cases

### **Use Case 1: Build Once, Install on Multiple Phones**

```powershell
# Build APK
.\build-apk-only.ps1

# Share APK file with others
# They can install on their phones
```

---

### **Use Case 2: Build on Work PC, Install on Personal Phone**

```powershell
# Build APK on work computer
.\build-apk-only.ps1

# Email APK to personal email
# Install on personal phone at home
```

---

### **Use Case 3: Create Backup APK**

```powershell
# Build and save to backup location
.\build-apk-only.ps1 -OutputFolder "D:\Backups\ScanDoc"
```

---

## 🎯 Next Steps After Installation

Once you install the APK on your phone:

1. ✅ Launch **ScanDoc** app
2. ✅ Wait for **"Tesseract ready for OCR"** toast
3. ✅ Go to **Scan** tab → Scan Marathi document
4. ✅ Go to **Pages** tab → Click **"Run OCR"**
5. ✅ Verify Marathi text displays correctly
6. ✅ Export to **DOCX** and **TXT** to verify

---

## 📚 Related Documentation

- **`AUTOMATED_INSTALLATION_README.md`** - Full automation with device
- **`QUICK_START_GUIDE.md`** - Testing guide
- **`MARATHI_OCR_IMPLEMENTATION.md`** - Implementation details
- **`CODE_CHANGES_REFERENCE.md`** - Code changes

---

## ✅ Summary

- ✅ **No device required** during build
- ✅ **APK saved** to easy-access location
- ✅ **Timestamped filename** for version tracking
- ✅ **Multiple transfer options** (USB, cloud, email)
- ✅ **Simple double-click** execution
- ✅ **Automatic folder opening** after build

---

## 🎉 You're Ready!

Just **double-click `build-apk.bat`** and the APK will be ready to transfer!

**Happy Building! 🚀📦**

