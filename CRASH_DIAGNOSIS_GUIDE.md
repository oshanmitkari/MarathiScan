# 🔍 ScanDoc Crash Diagnosis & Fix Guide

## 📋 Quick Diagnosis Steps

### **STEP 1: Capture Crash Logs**

Connect your phone via USB and run:

```powershell
cd C:\Users\oshan\Desktop\DTP\ScanDoc

# Option A: Run diagnostic script
powershell -ExecutionPolicy Bypass -File diagnose-crash.ps1

# Option B: Capture live crash log
powershell -ExecutionPolicy Bypass -File diagnose-crash.ps1 -CaptureLog
```

**Or use batch file:**
```
Double-click: capture-crash-logs.bat
```

---

### **STEP 2: Manual Log Capture (If Scripts Fail)**

```powershell
# Set ADB path
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Clear old logs
& $adb logcat -c

# Launch app on phone and wait for crash

# Capture crash log
& $adb logcat -d > crash_log.txt

# View crash log
notepad crash_log.txt
```

---

## 🐛 Common Crash Causes & Solutions

### **Cause 1: Traineddata Files Not Copied**

**Symptoms:**
- App crashes immediately on launch
- Log shows: "tessdata folder not found"
- Log shows: "FileNotFoundException" for traineddata files

**Diagnosis:**
```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb shell "run-as com.mk.scandoc ls -la /data/data/com.mk.scandoc/files/tessdata/"
```

**Expected Output:**
```
-rw------- eng.traineddata
-rw------- mar.traineddata
```

**If files are missing:**

**Solution:** Uninstall and reinstall app
```powershell
& $adb uninstall com.mk.scandoc
& $adb install -r "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_*.apk"
```

---

### **Cause 2: Unicode Characters in Code**

**Symptoms:**
- App crashes on specific Android versions
- Log shows: "IllegalArgumentException" or "UnsupportedEncodingException"

**Root Cause:** Emoji characters (✅, ❌, ⚠️) in Toast messages and Log statements

**Solution:** Rebuild with ASCII-only characters (see fix below)

---

### **Cause 3: Navigation Component Issue**

**Symptoms:**
- App crashes after splash screen
- Log shows: "IllegalArgumentException: navigation graph not found"
- Log shows: "InflateException" in activity_main.xml

**Diagnosis:**
Check log for:
```
android.view.InflateException: Binary XML file line #20
Caused by: java.lang.IllegalArgumentException
```

**Solution:** Navigation graph issue - check mobile_navigation.xml

---

### **Cause 4: Native Library Loading Failure**

**Symptoms:**
- App crashes immediately
- Log shows: "UnsatisfiedLinkError"
- Log shows: "couldn't find libtess.so" or similar

**Root Cause:** Tesseract native libraries not included in APK

**Solution:** Check build.gradle.kts for proper native library packaging

---

### **Cause 5: Android Version Incompatibility**

**Symptoms:**
- App crashes on older Android versions (< 8.0)
- Log shows: "MethodNotFoundException" or "NoClassDefFoundError"

**Diagnosis:**
Check your Android version:
```powershell
& $adb shell getprop ro.build.version.sdk
```

**Minimum Required:** API 26 (Android 8.0)

**If API < 26:** App won't work - need Android 8.0+

---

## 🔧 Quick Fixes

### **Fix 1: Remove Unicode Characters (Most Likely Fix)**

The Unicode emoji characters might be causing crashes. Let me create a fixed version.

**Files to modify:**
- `MainActivity.java` (lines 46, 48)
- `PagesFragment.java` (multiple Toast messages)

**Change:**
```java
// FROM:
Toast.makeText(this, "✅ Permission granted", Toast.LENGTH_SHORT).show();

// TO:
Toast.makeText(this, "[OK] Permission granted", Toast.LENGTH_SHORT).show();
```

---

### **Fix 2: Add Error Handling to MainActivity**

Wrap TesseractHelper call in try-catch:

```java
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    binding = ActivityMainBinding.inflate(getLayoutInflater());
    setContentView(binding.getRoot());

    try {
        TesseractHelper.copyTessDataFiles(this);
    } catch (Exception e) {
        Log.e("MainActivity", "Error copying tessdata: " + e.getMessage(), e);
        Toast.makeText(this, "Error initializing OCR: " + e.getMessage(), Toast.LENGTH_LONG).show();
    }

    // ... rest of code
}
```

---

### **Fix 3: Force Reinstall with Data Clear**

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Uninstall completely (clears all data)
& $adb uninstall com.mk.scandoc

# Reinstall
& $adb install "C:\Users\oshan\Desktop\ScanDoc_APK\ScanDoc_Debug_20260131_105738.apk"

# Launch app
& $adb shell am start -n com.mk.scandoc/.MainActivity

# Monitor logs
& $adb logcat -v time | Select-String "scandoc|AndroidRuntime"
```

---

## 📊 Diagnostic Commands Reference

### **Check App Installation**
```powershell
$adb shell pm list packages | Select-String "scandoc"
```

### **Check App Permissions**
```powershell
$adb shell dumpsys package com.mk.scandoc | Select-String "permission"
```

### **Check Traineddata Files**
```powershell
$adb shell "run-as com.mk.scandoc ls -la /data/data/com.mk.scandoc/files/tessdata/"
```

### **Get Device Info**
```powershell
$adb shell getprop ro.product.model
$adb shell getprop ro.build.version.release
$adb shell getprop ro.build.version.sdk
```

### **View Recent Crashes**
```powershell
$adb logcat -d -v time AndroidRuntime:E *:S
```

### **Monitor Live Logs**
```powershell
$adb logcat -v time | Select-String "scandoc|FATAL|AndroidRuntime"
```

### **Clear App Data (Without Uninstall)**
```powershell
$adb shell pm clear com.mk.scandoc
```

---

## 🎯 Next Steps

1. **Run diagnostic script:**
   ```powershell
   .\diagnose-crash.ps1
   ```

2. **Capture live crash log:**
   ```powershell
   .\diagnose-crash.ps1 -CaptureLog
   ```
   Then launch app on phone and wait for crash

3. **Share crash log** - Look for lines containing:
   - `FATAL EXCEPTION`
   - `AndroidRuntime`
   - `com.mk.scandoc`
   - `Caused by:`

4. **Check specific errors:**
   - NullPointerException
   - ClassNotFoundException
   - UnsatisfiedLinkError
   - InflateException

---

## 📝 What to Look For in Crash Log

```
FATAL EXCEPTION: main
Process: com.mk.scandoc, PID: 12345
java.lang.RuntimeException: Unable to start activity
    at android.app.ActivityThread.performLaunchActivity
Caused by: java.lang.NullPointerException
    at com.mk.scandoc.MainActivity.onCreate(MainActivity.java:29)
```

**Key Information:**
- **Exception Type:** NullPointerException
- **Location:** MainActivity.java line 29
- **Cause:** TesseractHelper.copyTessDataFiles(this) failed

---

## ✅ Expected Behavior (No Crash)

When app launches successfully, you should see in logcat:

```
D/TesseractHelper: Successfully copied: eng.traineddata
D/TesseractHelper: Successfully copied: mar.traineddata
D/TesseractHelper: Total traineddata files: 2
D/PagesFragment: Tesseract data path: /data/user/0/com.mk.scandoc/files
D/PagesFragment: Found traineddata files:
D/PagesFragment:   - eng.traineddata
D/PagesFragment:   - mar.traineddata
D/PagesFragment: Tesseract initialized successfully
```

---

## 🆘 If All Else Fails

I can create a crash-safe version with:
- ✅ All Unicode characters removed
- ✅ Enhanced error handling
- ✅ Detailed logging
- ✅ Graceful fallbacks

Just provide the crash log and I'll fix it immediately!

