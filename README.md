# MarathiScan - Document Scanner & OCR App

[![Android](https://img.shields.io/badge/Platform-Android-green.svg)](https://developer.android.com/)
[![Java](https://img.shields.io/badge/Language-Java-orange.svg)](https://www.java.com/)
[![Tesseract](https://img.shields.io/badge/OCR-Tesseract%203.05-blue.svg)](https://github.com/tesseract-ocr/tesseract)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

**MarathiScan** is an Android document scanner and OCR application with native support for **Marathi (Devanagari script)** and **English** text recognition. Scan documents, extract text with preserved formatting, and export to Microsoft Word DOCX format.

---

## 📱 Features

### 🔍 **OCR Text Recognition**
- **Bilingual Support:** Marathi (Devanagari) and English
- **Tesseract OCR Engine:** Version 3.05.00 (tess-two 9.1.0)
- **High Accuracy:** Optimized traineddata files for both languages
- **Real-time Processing:** Fast text extraction from scanned images

### 📄 **Document Input**
- **Camera Scanning:** Built-in document scanner with Google ML Kit
- **File Upload:** Support for images (JPG, PNG) and PDF files
- **PDF Processing:** Extract and process individual pages from PDF documents
- **Multi-page Support:** Process multiple pages in a single session

### 📝 **Word Export (DOCX)**
- **Apache POI Integration:** Professional Word document generation
- **Formatting Preservation:** Maintains headings, paragraphs, and line breaks
- **A4 Page Layout:** Standard 210mm × 297mm page size with 25mm margins
- **Devanagari Font Support:** "Noto Sans Devanagari" for proper Marathi rendering
- **Intelligent Spacing:** Low-level XML manipulation for correct word spacing
- **1.5 Line Spacing:** Optimized for Devanagari readability

### 🎨 **User Interface**
- **Material Design:** Modern, intuitive Android UI
- **Bottom Navigation:** Easy access to Scan, Pages, and Files tabs
- **RecyclerView Lists:** Efficient display of scanned pages and OCR results
- **Progress Indicators:** Real-time feedback during OCR processing

---

## 🚀 Getting Started

### Prerequisites

- **Android Studio:** Arctic Fox or later
- **JDK:** Version 17
- **Android SDK:** API Level 24 (Android 7.0) or higher
- **Gradle:** 8.0+

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/oshanmitkari/MarathiScan.git
   cd MarathiScan
   ```

2. **Open in Android Studio:**
   - Launch Android Studio
   - Select "Open an Existing Project"
   - Navigate to the cloned directory

3. **Sync Gradle:**
   - Android Studio will automatically sync Gradle dependencies
   - Wait for the sync to complete

4. **Build the APK:**
   ```bash
   ./gradlew assembleDebug
   ```

5. **Install on Device:**
   - Connect your Android device via USB
   - Enable USB debugging
   - Run the app from Android Studio or use:
   ```bash
   ./gradlew installDebug
   ```

### Quick Deploy (Windows)

Use the automated deployment script:
```powershell
.\deploy-app-now.ps1
```

This script will:
- Clean previous builds
- Build the APK
- Uninstall old version
- Install new APK
- Launch the app

---

## 📖 Usage

### 1. **Scan a Document**
- Open the app and navigate to the **Scan** tab
- Tap "Scan Document" to launch the camera
- Capture the document (auto-detection enabled)
- Review and confirm the scanned image

### 2. **Run OCR**
- Go to the **Pages** tab
- Select the language: Marathi, English, or Both
- Tap "Run OCR" to extract text
- View the extracted text in the results list

### 3. **Export to Word**
- After OCR processing, tap "Export Word DOCX"
- The file will be saved to: `/storage/emulated/0/Documents/ScanDoc/`
- Open the file in Microsoft Word or WPS Office

---

## 🛠️ Technical Details

### Architecture
- **Pattern:** MVVM (Model-View-ViewModel)
- **Language:** Java
- **Min SDK:** 24 (Android 7.0)
- **Target SDK:** 34 (Android 14)

### Key Dependencies

```gradle
// Tesseract OCR
implementation 'com.rmtheis:tess-two:9.1.0'

// Apache POI for Word export
implementation 'org.apache.poi:poi:5.3.0'
implementation 'org.apache.poi:poi-ooxml:5.3.0'

// Google ML Kit Document Scanner
implementation 'com.google.android.gms:play-services-mlkit-document-scanner:16.0.0-beta1'

// AndroidX Libraries
implementation 'androidx.appcompat:appcompat:1.6.1'
implementation 'androidx.navigation:navigation-fragment:2.7.7'
implementation 'androidx.recyclerview:recyclerview:1.3.2'
```

### Project Structure

```
MarathiScan/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/mk/scandoc/
│   │   │   │   ├── MainActivity.java
│   │   │   │   ├── ui/
│   │   │   │   │   ├── scan/          # Document scanning
│   │   │   │   │   ├── pages/         # OCR processing & export
│   │   │   │   │   └── files/         # File management
│   │   │   │   └── utils/
│   │   │   │       ├── TesseractHelper.java    # OCR engine
│   │   │   │       └── DocumentProcessor.java  # PDF processing
│   │   │   ├── assets/
│   │   │   │   └── tessdata/
│   │   │   │       ├── eng.traineddata  # English (21.88 MB)
│   │   │   │       └── mar.traineddata  # Marathi (14.24 MB)
│   │   │   └── res/                     # Android resources
│   │   └── test/
│   └── build.gradle.kts
├── gradle/
├── docs/                                # Comprehensive documentation
└── scripts/                             # PowerShell deployment scripts
```

---

## 🔧 Configuration

### Tesseract OCR Setup

The app includes pre-configured Tesseract traineddata files:
- **English:** `eng.traineddata` (Tesseract 3.04.00 compatible)
- **Marathi:** `mar.traineddata` (Tesseract 3.04.00 compatible)

Files are automatically copied to the app's internal storage on first launch:
```
/data/data/com.mk.scandoc/files/tesseract/tessdata/
```

### Word Export Configuration

DOCX files are saved to the public Documents folder:
```
/storage/emulated/0/Documents/ScanDoc/
```

File naming format: `ScanDoc_OCR_[timestamp].docx`

---

## 📚 Documentation

Comprehensive documentation is available in the repository:

- **[QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)** - Get started quickly
- **[MARATHI_OCR_IMPLEMENTATION.md](MARATHI_OCR_IMPLEMENTATION.md)** - Marathi OCR details
- **[WORD_EXPORT_GUIDE.md](WORD_EXPORT_GUIDE.md)** - DOCX export implementation
- **[PDF_DOC_INPUT_SUPPORT.md](PDF_DOC_INPUT_SUPPORT.md)** - PDF processing guide
- **[FORMATTING_PRESERVATION_UPDATE.md](FORMATTING_PRESERVATION_UPDATE.md)** - Document formatting
- **[BUILD_AND_INSTALL_GUIDE.md](BUILD_AND_INSTALL_GUIDE.md)** - Build instructions

---

## 🐛 Known Issues & Solutions

### Issue: Marathi Word Spacing in DOCX

**Problem:** Marathi words may appear joined together in exported DOCX files.

**Root Cause:** Microsoft Word requires explicit `xml:space="preserve"` attribute on text nodes for Devanagari scripts.

**Solution:** The app uses low-level Apache POI CTText API to create separate XML nodes for each word and space character with proper attributes.

**Status:** Implementation in progress (see diagnostic logs in `PagesFragment.java`)

---

## 📄 License

**Copyright © 2026 Oshan Mitkari. All Rights Reserved.**

This project is licensed under a **Proprietary License**.

**This software is NOT open-source and is NOT available for:**
- ❌ Copying or reproduction
- ❌ Modification or derivative works
- ❌ Distribution or redistribution
- ❌ Commercial use without permission
- ❌ Reverse engineering

**Permitted use:**
- ✅ Viewing source code for educational/reference purposes only
- ✅ Using the compiled APK for personal, non-commercial use only

See the [LICENSE](LICENSE) file for complete terms.

For licensing inquiries or permission requests, please contact the author.

---

## 👨‍💻 Author

**Oshan Mitkari**
- GitHub: [@oshanmitkari](https://github.com/oshanmitkari)

---

## 🙏 Acknowledgments

- **Tesseract OCR** - Open-source OCR engine
- **tess-two** - Android port of Tesseract
- **Apache POI** - Java API for Microsoft Documents
- **Google ML Kit** - Document scanning capabilities
- **Noto Fonts** - Devanagari font support

---

## 📞 Support

For issues, questions, or suggestions:
- Open an [Issue](https://github.com/oshanmitkari/MarathiScan/issues)
- Check existing [Documentation](docs/)

---

## 🗺️ Roadmap

- [ ] Fix Marathi word spacing in DOCX export
- [ ] Add support for more Indian languages (Hindi, Gujarati, etc.)
- [ ] Implement cloud storage integration
- [ ] Add batch processing for multiple documents
- [ ] Improve OCR accuracy with custom training
- [ ] Add PDF export functionality
- [ ] Implement text search within scanned documents

---

**Made with ❤️ for the Marathi-speaking community**

