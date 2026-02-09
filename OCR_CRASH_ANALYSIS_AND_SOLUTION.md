# 🔴 OCR CRASH ANALYSIS AND SOLUTION

## 📊 CRASH DETAILS

**Date:** January 31, 2026  
**Issue:** Native crash (SIGABRT) when calling `tessAPI.init()`

### Crash Log:
```
01-31 16:59:53.147  9279  9792 D PagesFragment: Calling tessAPI.init()...
01-31 16:59:53.172  9279  9330 F libc    : Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 9330 (RenderThread)
01-31 16:59:53.808  9795  9795 F DEBUG   : #01 pc 000000000008c83c  /apex/com.android.runtime/lib64/bionic/libc.so 
(__fortify_fatal(char const*, ...)+124)
```

**Error Type:** `__fortify_fatal` - Buffer overflow or memory corruption in native Tesseract library

---

## 🔍 ROOT CAUSE IDENTIFIED

### The Problem: **Traineddata Version Incompatibility**

**tess-two 9.1.0 uses Tesseract 3.05.00** (confirmed from CHANGELOG.md)

**Current traineddata files:** tessdata_fast (Tesseract 3.x/4.x compatible)
- mar.traineddata: 2.02 MB (2,118,233 bytes)
- eng.traineddata: 3.92 MB (4,113,088 bytes)

**Issue:** These tessdata_fast files are causing native crashes with tess-two 9.1.0

---

## ✅ SOLUTION: Use Tesseract 3.04.00 Traineddata Files

According to the official Tesseract documentation:
https://github.com/tesseract-ocr/tessdoc/blob/main/tess3/Data-Files.md

**For Tesseract 3.04/3.05, use these specific traineddata files:**

### Download Links:

**Marathi:**
```
https://github.com/tesseract-ocr/tessdata/raw/3.04.00/mar.traineddata
```

**English:**
```
https://github.com/tesseract-ocr/tessdata/raw/3.04.00/eng.traineddata
```

---

## 📝 TRAINEDDATA VERSION HISTORY

| Attempt | Repository | Tesseract Version | Result |
|---------|-----------|-------------------|--------|
| 1 | tessdata_best | 5.x | ❌ Native crash |
| 2 | tessdata | 4.x | ❌ Native crash |
| 3 | tessdata_fast | 3.x/4.x | ❌ Native crash (current state) |
| **4** | **tessdata 3.04.00** | **3.04/3.05** | **✅ Should work!** |

---

## 🛠️ IMPLEMENTATION STEPS

### Step 1: Download Correct Traineddata Files

Download the Tesseract 3.04.00 compatible files:
- mar.traineddata (for Marathi)
- eng.traineddata (for English)

### Step 2: Replace Files in Assets

Replace the current files in:
```
ScanDoc/app/src/main/assets/tessdata/
```

### Step 3: Rebuild and Test

1. Rebuild APK
2. Uninstall old app
3. Install new APK
4. Scan a document
5. Run OCR
6. Verify no crash occurs

---

## 🎯 EXPECTED OUTCOME

With the correct Tesseract 3.04.00 traineddata files:
- ✅ No native crash during `tessAPI.init()`
- ✅ OCR initialization succeeds
- ✅ Text extraction works for both Marathi and English

---

## 📚 TECHNICAL DETAILS

### tess-two 9.1.0 Specifications:
- **Tesseract Version:** 3.05.00
- **Release Date:** March 17, 2022
- **Compatible Traineddata:** 3.04.00 branch

### File Locations:
- **Assets:** `app/src/main/assets/tessdata/`
- **Runtime:** `/data/user/0/com.mk.scandoc/files/tesseract/tessdata/`
- **dataPath for init:** `/data/user/0/com.mk.scandoc/files/tesseract`

---

## 🔗 REFERENCES

- tess-two GitHub: https://github.com/rmtheis/tess-two
- tess-two CHANGELOG: https://github.com/rmtheis/tess-two/blob/master/CHANGELOG.md
- Tesseract 3.x Data Files: https://github.com/tesseract-ocr/tessdoc/blob/main/tess3/Data-Files.md
- tessdata 3.04.00: https://github.com/tesseract-ocr/tessdata/tree/3.04.00

---

## ⚠️ IMPORTANT NOTES

1. **Do NOT use tessdata_best** - These are for Tesseract 5.x
2. **Do NOT use tessdata (main branch)** - These are for Tesseract 4.x
3. **Do NOT use tessdata_fast** - These are causing crashes with tess-two 9.1.0
4. **ONLY use tessdata 3.04.00 branch** - These are specifically for Tesseract 3.04/3.05

---

**Next Action:** Download and install the correct traineddata files from the 3.04.00 branch.

