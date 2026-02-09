# 🚀 ScanDoc - Complete Build & Installation Guide

## 📋 Quick Decision Guide

**Choose your installation method:**

| Scenario | Use This Script | Documentation |
|----------|----------------|---------------|
| 🔌 **Phone connected now** → Want automatic installation | `quick-install.bat` | [AUTOMATED_INSTALLATION_README.md](AUTOMATED_INSTALLATION_README.md) |
| 📦 **No phone connected** → Build APK to transfer later | `build-apk.bat` | [BUILD_APK_STANDALONE_README.md](BUILD_APK_STANDALONE_README.md) |

---

## 🎯 Option 1: Full Automation (Phone Connected)

### **When to Use:**
- ✅ Phone is connected via USB right now
- ✅ USB Debugging is enabled
- ✅ Want everything done automatically
- ✅ Want to test immediately

### **What It Does:**
1. Checks prerequisites (Java, Android SDK, ADB)
2. Detects your connected phone
3. Builds the APK
4. Installs on your phone automatically
5. Launches the app
6. Monitors logs in real-time

### **How to Run:**

**Double-Click Method:**
```
Double-click: quick-install.bat
```

**PowerShell Method:**
```powershell
cd C:\Users\oshan\Desktop\DTP\ScanDoc
powershell -ExecutionPolicy Bypass -File auto-build-install.ps1 -LaunchApp
```

### **Time Required:**
- First run: 4-6 minutes
- Subsequent runs: 1-2 minutes

### **Prerequisites:**
- ✅ Java installed (already have version 22 ✓)
- ✅ Android SDK installed (already have it ✓)
- ✅ Phone connected via USB
- ✅ USB Debugging enabled on phone

📖 **Full Documentation:** [AUTOMATED_INSTALLATION_README.md](AUTOMATED_INSTALLATION_README.md)

---

## 📦 Option 2: Standalone Build (No Phone Required)

### **When to Use:**
- ✅ Phone is NOT connected right now
- ✅ Want to build APK to transfer later
- ✅ Want to share APK via email/cloud
- ✅ Want to install on multiple phones
- ✅ Building on one PC, installing on phone later

### **What It Does:**
1. Checks Java installation
2. Builds the APK
3. Copies APK to Desktop folder with timestamp
4. Opens folder containing APK
5. Shows installation instructions

### **How to Run:**

**Double-Click Method:**
```
Double-click: build-apk.bat
```

**PowerShell Method:**
```powershell
cd C:\Users\oshan\Desktop\DTP\ScanDoc
powershell -ExecutionPolicy Bypass -File build-apk-only.ps1
```

### **Time Required:**
- First run: 3-5 minutes
- Subsequent runs: 30-60 seconds

### **Prerequisites:**
- ✅ Java installed (already have version 22 ✓)
- ❌ Phone NOT required
- ❌ Android SDK NOT required (only Java needed)

### **APK Output Location:**
```
C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_20260131_143022.apk
```

### **Transfer Methods:**
- 📁 USB cable (copy to phone's Download folder)
- ☁️ Cloud storage (Google Drive, Dropbox, OneDrive)
- 📧 Email (send to yourself)
- 🔗 ADB (if you connect phone later)

📖 **Full Documentation:** [BUILD_APK_STANDALONE_README.md](BUILD_APK_STANDALONE_README.md)

---

## 📊 Comparison Table

| Feature | Full Automation<br>`quick-install.bat` | Standalone Build<br>`build-apk.bat` |
|---------|----------------------------------------|-------------------------------------|
| **Phone Required** | ✅ Yes (must be connected) | ❌ No |
| **USB Debugging Required** | ✅ Yes | ❌ No |
| **Android SDK Required** | ✅ Yes | ❌ No (only Java) |
| **Builds APK** | ✅ Yes | ✅ Yes |
| **Installs Automatically** | ✅ Yes | ❌ No (manual transfer) |
| **Launches App** | ✅ Yes | ❌ No |
| **Monitors Logs** | ✅ Yes | ❌ No |
| **APK Saved for Later** | ❌ No | ✅ Yes (Desktop folder) |
| **Best For** | Quick testing | Building to transfer later |
| **Time (first run)** | 4-6 minutes | 3-5 minutes |
| **Time (subsequent)** | 1-2 minutes | 30-60 seconds |

---

## 🎯 Recommended Workflow

### **For First-Time Testing:**

1. **Build APK** (no phone needed):
   ```
   Double-click: build-apk.bat
   ```

2. **Transfer to phone** via your preferred method (USB, cloud, email)

3. **Install manually** on phone

4. **Test Marathi OCR** functionality

### **For Iterative Development:**

1. **Make code changes**

2. **Connect phone** via USB

3. **Run full automation**:
   ```
   Double-click: quick-install.bat
   ```

4. **Test immediately** (app launches automatically)

---

## 📱 Manual Installation Steps (After Building APK)

### **Method 1: USB Transfer**

1. Connect phone to PC via USB
2. Copy APK from `C:\Users\oshan\Desktop\ScanDoc_APK\` to phone's Download folder
3. On phone: File Manager → Downloads → Tap APK → Install

### **Method 2: Cloud Storage**

1. Upload APK to Google Drive / Dropbox / OneDrive
2. On phone: Open cloud app → Download APK → Tap to install

### **Method 3: Email**

1. Email APK to yourself
2. On phone: Open email → Download attachment → Tap to install

### **Method 4: ADB (if phone connected later)**

```powershell
adb install -r "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_*.apk"
```

---

## 🔧 Advanced Options

### **Clean Build** (if build fails)

```powershell
# Full automation with clean build
.\auto-build-install.ps1 -CleanBuild -LaunchApp

# Standalone build with clean
.\build-apk-only.ps1 -CleanBuild
```

### **Custom Output Folder**

```powershell
# Save APK to Downloads
.\build-apk-only.ps1 -OutputFolder "$env:USERPROFILE\Downloads\ScanDoc"

# Save to USB drive
.\build-apk-only.ps1 -OutputFolder "D:\ScanDoc_APK"
```

### **Install Only** (skip build, use existing APK)

```powershell
.\auto-build-install.ps1 -InstallOnly
```

---

## 📚 Complete Documentation Index

| Document | Description |
|----------|-------------|
| **BUILD_AND_INSTALL_GUIDE.md** | 👈 You are here - Master guide |
| **AUTOMATED_INSTALLATION_README.md** | Full automation details |
| **BUILD_APK_STANDALONE_README.md** | Standalone build details |
| **QUICK_START_GUIDE.md** | 5-minute testing guide |
| **MARATHI_OCR_IMPLEMENTATION.md** | Implementation details |
| **CODE_CHANGES_REFERENCE.md** | Code changes with line numbers |
| **ANALYSIS_REPORT.md** | Detailed analysis of fixes |

---

## ✅ Prerequisites Summary

### **For Full Automation (`quick-install.bat`):**
- ✅ Java 11+ (you have version 22 ✓)
- ✅ Android SDK (you have it ✓)
- ✅ ADB (included in Android SDK)
- ✅ Phone connected via USB
- ✅ USB Debugging enabled

### **For Standalone Build (`build-apk.bat`):**
- ✅ Java 11+ (you have version 22 ✓)
- ❌ Nothing else required!

---

## 🎉 You're Ready!

**Choose your method and get started:**

- 🔌 **Phone connected?** → Double-click `quick-install.bat`
- 📦 **No phone?** → Double-click `build-apk.bat`

**Happy Building & Testing! 🚀📱**

