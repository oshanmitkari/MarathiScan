# 🚀 Quick Start Guide - Marathi OCR Testing

## ⚡ 5-Minute Setup

### Step 1: Build the App (1 minute)
```bash
cd ScanDoc
./gradlew clean assembleDebug
```

### Step 2: Install on Device (30 seconds)
```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### Step 3: Launch and Test (3 minutes)
1. Open **ScanDoc** app
2. Go to **Scan** tab
3. Click **"Scan Document"**
4. Scan a page with **printed Marathi text**
5. Go to **Pages** tab
6. Click **"Run OCR (Marathi + English)"**
7. Wait for processing to complete
8. Verify Marathi text appears correctly in the preview

### Step 4: Export and Verify (30 seconds)
1. Click **"Export Word DOCX"**
2. Open the exported file in Microsoft Word or Google Docs
3. Verify Marathi text displays correctly
4. Click **"Export PDF"** (temporarily mapped to text export)
5. Open the `.txt` file in a text editor
6. Verify UTF-8 encoding and Marathi characters

---

## 📍 What Changed?

### Before ❌
- Tesseract initialized with `"eng"` only
- Marathi text not recognized
- DOCX export showed boxes (□) for Marathi
- No text export option

### After ✅
- Tesseract initialized with `"mar+eng"`
- Marathi + English text recognized
- DOCX export uses "Noto Sans Devanagari" font
- UTF-8 text export available

---

## 🧪 Test Checklist

- [ ] App builds without errors
- [ ] App installs on device
- [ ] Tesseract initializes successfully (check toast message)
- [ ] Marathi text recognized in OCR
- [ ] English text recognized in OCR
- [ ] Mixed Marathi+English documents work
- [ ] DOCX export displays Marathi correctly in Word
- [ ] DOCX export displays Marathi correctly in Google Docs
- [ ] TXT export preserves Marathi characters
- [ ] TXT file encoding is UTF-8

---

## 📂 Where to Find Exported Files

### Android 10+ (API 29+)
```
/storage/emulated/0/Android/data/com.mk.scandoc/files/Documents/ScanDoc/
```

### Android 9 and below
```
/storage/emulated/0/Download/ScanDoc/
```

**Access via:**
- File Manager app → Documents → ScanDoc
- Or check the toast message after export for exact path

---

## 🐛 Troubleshooting

### "Tesseract data not found" error
**Solution:** Uninstall and reinstall the app to trigger traineddata copy.

### Marathi text shows as boxes in DOCX
**Solution:** Open in Google Docs instead of older Word versions.

### OCR returns empty text
**Solution:** 
- Ensure good lighting when scanning
- Text should be clear and in focus
- Try rescanning the page

### Build fails
**Solution:**
```bash
./gradlew clean
./gradlew build --refresh-dependencies
```

---

## 📞 Support

**Documentation:**
- `ANALYSIS_REPORT.md` - Detailed analysis of issues and fixes
- `MARATHI_OCR_IMPLEMENTATION.md` - Complete implementation guide
- `CODE_CHANGES_REFERENCE.md` - Exact code changes with line numbers

**Logs:**
```bash
# View real-time logs
adb logcat | grep -E "PagesFragment|Tesseract"

# Check Tesseract initialization
adb logcat | grep "Tesseract"

# Check OCR processing
adb logcat | grep "Page.*exported"
```

---

## ✅ Success Criteria

Your Marathi OCR implementation is working correctly if:

1. ✅ Toast shows "✅ Tesseract ready for OCR" on app launch
2. ✅ Marathi text appears in OCR results preview (no �, □, or broken glyphs)
3. ✅ DOCX file opens in Word/Google Docs with readable Marathi text
4. ✅ TXT file shows Marathi characters correctly in text editors
5. ✅ Mixed Marathi+English documents process correctly

---

## 🎯 Next Steps (Optional)

### Add Dedicated Text Export Button
Edit `fragment_pages.xml` to add a button between Word and PDF export buttons.

### Implement PDF Export
Use iText or PDFBox with Devanagari font embedding.

### Add Language Selection UI
Allow users to choose between `mar+eng`, `eng+mar`, or single language.

### Optimize OCR Accuracy
Experiment with Tesseract PSM (Page Segmentation Mode) settings:
```java
tessAPI.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO);
```

---

## 📊 Performance Expectations

| Operation | Time (Low-end Device) | Time (High-end Device) |
|-----------|----------------------|------------------------|
| Tesseract Init | 2-3 seconds | 1 second |
| OCR per page | 3-5 seconds | 1-2 seconds |
| DOCX Export | 1-2 seconds | <1 second |
| TXT Export | <1 second | <1 second |

**Note:** Marathi OCR is slightly slower than English due to larger character set.

---

## 🎉 You're Ready!

All Marathi OCR functionality is now implemented and ready for testing. Follow the steps above to verify everything works correctly.

**Happy Testing! 🚀**

