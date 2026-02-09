package com.mk.scandoc.ui.pages;

import android.Manifest;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.mk.scandoc.databinding.FragmentPagesBinding;
import com.mk.scandoc.ui.files.FilesViewModel;
import com.mk.scandoc.ui.files.PageData;
import com.googlecode.tesseract.android.TessBaseAPI;
import org.apache.poi.xwpf.usermodel.ParagraphAlignment;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;
import org.apache.poi.xwpf.usermodel.LineSpacingRule;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTPageSz;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTPageMar;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTSectPr;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTBody;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTR;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTText;
import org.apache.xmlbeans.impl.xb.xmlschema.SpaceAttribute.Space;
import java.math.BigInteger;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import android.os.Handler;
import android.os.Looper;

public class PagesFragment extends Fragment {
    private static final String TAG = "PagesFragment";
    private FragmentPagesBinding binding;
    private FilesViewModel sharedViewModel;
    private OcrResultsAdapter adapter;
    private TessBaseAPI tessAPI;
    private static final int STORAGE_PERMISSION_CODE = 101;
    private ExecutorService executorService;
    private Handler mainHandler;
    private boolean tessInitialized = false;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentPagesBinding.inflate(inflater, container, false);
        sharedViewModel = new ViewModelProvider(requireActivity()).get(FilesViewModel.class);

        executorService = Executors.newSingleThreadExecutor();
        mainHandler = new Handler(Looper.getMainLooper());

        setupRecyclerView();
        setupButtons();
        observeData();
        // ✅ FIX: Do NOT initialize Tesseract automatically
        // It will be initialized lazily when user clicks "Run OCR"
        // This prevents crashes when fragment loads with no pages or missing traineddata files

        return binding.getRoot();
    }

    private void setupRecyclerView() {
        adapter = new OcrResultsAdapter();
        android.content.Context context = getContext();
        if (context != null) {
            binding.recyclerOcrResults.setLayoutManager(new LinearLayoutManager(context));
            binding.recyclerOcrResults.setAdapter(adapter);
        }
    }

    private void setupButtons() {
        binding.btnRunOcr.setOnClickListener(v -> runOcrOnAllPages());
        binding.btnExportWord.setOnClickListener(v -> exportWord());
        binding.btnExportPdf.setOnClickListener(v -> exportPdf());
        binding.btnExportDtp.setOnClickListener(v -> exportDtp());
    }

    private void initTesseract() {
        // ✅ GUARD 1: Fragment lifecycle check
        if (!isAdded() || getContext() == null) {
            Log.e(TAG, "Fragment not attached, cannot initialize Tesseract");
            return;
        }

        // ✅ GUARD 2: Check if already initialized
        if (tessInitialized && tessAPI != null) {
            Log.d(TAG, "Tesseract already initialized, skipping");
            return;
        }

        // ✅ GUARD 3: Verify traineddata files exist BEFORE attempting init
        final android.content.Context context = getContext();
        if (context == null) {
            Log.e(TAG, "Context became null, cannot initialize Tesseract");
            return;
        }

        File tesseractDir = new File(context.getFilesDir(), "tesseract");
        File tessDataDir = new File(tesseractDir, "tessdata");
        File marFile = new File(tessDataDir, "mar.traineddata");
        File engFile = new File(tessDataDir, "eng.traineddata");

        Log.d(TAG, "=== Pre-initialization File Checks ===");
        Log.d(TAG, "Files directory: " + context.getFilesDir().getAbsolutePath());
        Log.d(TAG, "tessdata dir path: " + tessDataDir.getAbsolutePath());
        Log.d(TAG, "tessdata dir exists: " + tessDataDir.exists());
        Log.d(TAG, "tessdata dir is directory: " + tessDataDir.isDirectory());
        Log.d(TAG, "tessdata dir can read: " + tessDataDir.canRead());

        if (tessDataDir.exists()) {
            String[] files = tessDataDir.list();
            if (files != null) {
                Log.d(TAG, "Files in tessdata directory: " + files.length);
                for (String file : files) {
                    File f = new File(tessDataDir, file);
                    Log.d(TAG, "  - " + file + " (" + f.length() + " bytes)");
                }
            } else {
                Log.e(TAG, "tessdata.list() returned null - directory may not be readable");
            }
        }

        Log.d(TAG, "mar.traineddata:");
        Log.d(TAG, "  - Path: " + marFile.getAbsolutePath());
        Log.d(TAG, "  - Exists: " + marFile.exists());
        Log.d(TAG, "  - Size: " + marFile.length() + " bytes");
        Log.d(TAG, "  - Can read: " + marFile.canRead());

        Log.d(TAG, "eng.traineddata:");
        Log.d(TAG, "  - Path: " + engFile.getAbsolutePath());
        Log.d(TAG, "  - Exists: " + engFile.exists());
        Log.d(TAG, "  - Size: " + engFile.length() + " bytes");
        Log.d(TAG, "  - Can read: " + engFile.canRead());

        // Check if files exist
        if (!marFile.exists() || !engFile.exists()) {
            Log.e(TAG, "CRITICAL: Traineddata files missing");
            Log.e(TAG, "  mar.traineddata exists: " + marFile.exists());
            Log.e(TAG, "  eng.traineddata exists: " + engFile.exists());
            Log.w(TAG, "Attempting fallback copy operation...");

            // FALLBACK: Try to copy files again (in case MainActivity copy failed)
            boolean copySuccess = false;
            try {
                copySuccess = com.mk.scandoc.utils.TesseractHelper.copyTrainedDataIfNeeded(context);
                Log.d(TAG, "Fallback copy result: " + copySuccess);
            } catch (Exception copyException) {
                Log.e(TAG, "Fallback copy failed with exception: " + copyException.getMessage(), copyException);
            }

            // Re-check after fallback copy
            if (copySuccess && marFile.exists() && engFile.exists()) {
                Log.d(TAG, "[OK] Fallback copy succeeded! Files now exist:");
                Log.d(TAG, "  mar.traineddata: " + marFile.length() + " bytes");
                Log.d(TAG, "  eng.traineddata: " + engFile.length() + " bytes");
                // Continue with initialization (don't return)
            } else {
                Log.e(TAG, "FATAL: Traineddata files still missing after fallback copy");
                Log.e(TAG, "  mar.traineddata exists: " + marFile.exists());
                Log.e(TAG, "  eng.traineddata exists: " + engFile.exists());
                Log.e(TAG, "  tessdata dir exists: " + tessDataDir.exists());
                Log.e(TAG, "  tessdata dir path: " + tessDataDir.getAbsolutePath());

                // Check if assets exist
                try {
                    String[] assetFiles = context.getAssets().list("tessdata");
                    if (assetFiles != null && assetFiles.length > 0) {
                        Log.e(TAG, "  Assets in APK tessdata folder: " + assetFiles.length);
                        for (String assetFile : assetFiles) {
                            Log.e(TAG, "    - " + assetFile);
                        }
                    } else {
                        Log.e(TAG, "  [CRITICAL] No assets found in APK tessdata folder!");
                        Log.e(TAG, "  This indicates the APK was built incorrectly or assets are missing");
                    }
                } catch (Exception assetException) {
                    Log.e(TAG, "  Failed to list assets: " + assetException.getMessage(), assetException);
                }

                mainHandler.post(() -> {
                    if (isAdded() && getContext() != null && binding != null) {
                        binding.btnRunOcr.setEnabled(false);
                        binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                        Toast.makeText(getContext(),
                            "[ERROR] OCR language files missing. Please reinstall app.",
                            Toast.LENGTH_LONG).show();
                    }
                });
                tessInitialized = false;
                return; // ✅ CRITICAL: Exit immediately - do NOT attempt initialization
            }
        }

        // Check if files are valid with PROPER size thresholds
        // mar.traineddata (tessdata_fast): ~2MB (Tesseract 3.x/4.x compatible)
        // eng.traineddata (tessdata_fast): ~4MB (Tesseract 3.x/4.x compatible)
        final long MIN_MAR_SIZE = 2 * 1024 * 1024; // 2MB (tessdata_fast version is ~2MB)
        final long MIN_ENG_SIZE = 3 * 1024 * 1024;  // 3MB (tessdata_fast version is ~4MB)

        boolean filesValid = true;
        String sizeError = null;

        if (marFile.length() < MIN_MAR_SIZE) {
            filesValid = false;
            sizeError = "mar.traineddata is too small: " + marFile.length() + " bytes (expected > 10MB)";
            Log.e(TAG, "CRITICAL: " + sizeError);
        }

        if (engFile.length() < MIN_ENG_SIZE) {
            filesValid = false;
            sizeError = "eng.traineddata is too small: " + engFile.length() + " bytes (expected > 4MB)";
            Log.e(TAG, "CRITICAL: " + sizeError);
        }

        if (!filesValid) {
            Log.e(TAG, "CRITICAL: Traineddata files are corrupted or incomplete");
            Log.e(TAG, "  mar.traineddata size: " + marFile.length() + " bytes (minimum: " + MIN_MAR_SIZE + " bytes)");
            Log.e(TAG, "  eng.traineddata size: " + engFile.length() + " bytes (minimum: " + MIN_ENG_SIZE + " bytes)");
            Log.e(TAG, "ACTION REQUIRED: Delete app data and reinstall to re-copy traineddata files");

            final String errorMsg = sizeError;
            mainHandler.post(() -> {
                if (isAdded() && getContext() != null && binding != null) {
                    binding.btnRunOcr.setEnabled(false);
                    binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                    Toast.makeText(getContext(),
                        "[ERROR] OCR language files are corrupted. Please clear app data and reinstall.",
                        Toast.LENGTH_LONG).show();
                }
            });
            tessInitialized = false;
            return;
        }

        Log.d(TAG, "All file checks passed. Files are valid.");
        Log.d(TAG, "  mar.traineddata: " + marFile.length() + " bytes (>= " + MIN_MAR_SIZE + " bytes) ✓");
        Log.d(TAG, "  eng.traineddata: " + engFile.length() + " bytes (>= " + MIN_ENG_SIZE + " bytes) ✓");
        Log.d(TAG, "======================================");

        // Only NOW proceed with actual initialization in background thread
        executorService.execute(() -> {
            try {
                Log.d(TAG, "=== Starting Tesseract initialization ===");

                // CRITICAL: Wrap TessBaseAPI creation in try-catch to catch native crashes
                TessBaseAPI tempAPI = null;
                try {
                    Log.d(TAG, "Creating TessBaseAPI instance...");
                    tempAPI = new TessBaseAPI();
                    Log.d(TAG, "TessBaseAPI instance created successfully");
                } catch (UnsatisfiedLinkError e) {
                    Log.e(TAG, "FATAL: Native library loading failed", e);
                    Log.e(TAG, "UnsatisfiedLinkError: " + e.getMessage());
                    mainHandler.post(() -> {
                        if (isAdded() && getContext() != null && binding != null) {
                            Toast.makeText(getContext(),
                                "[ERROR] OCR native library failed to load. Please reinstall app.",
                                Toast.LENGTH_LONG).show();
                            binding.btnRunOcr.setEnabled(false);
                            binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                        }
                    });
                    tessInitialized = false;
                    return;
                } catch (Exception e) {
                    Log.e(TAG, "FATAL: Exception creating TessBaseAPI", e);
                    Log.e(TAG, "Exception: " + e.getMessage());
                    mainHandler.post(() -> {
                        if (isAdded() && getContext() != null && binding != null) {
                            Toast.makeText(getContext(),
                                "[ERROR] OCR initialization failed: " + e.getMessage(),
                                Toast.LENGTH_LONG).show();
                            binding.btnRunOcr.setEnabled(false);
                            binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                        }
                    });
                    tessInitialized = false;
                    return;
                }

                tessAPI = tempAPI;
                String dataPath = com.mk.scandoc.utils.TesseractHelper.getDataPath(context);

                Log.d(TAG, "Data path for init: " + dataPath);
                Log.d(TAG, "Expected tessdata location: " + dataPath + "/tessdata/");

                // Double-check directory accessibility
                if (!tessDataDir.exists() || !tessDataDir.isDirectory()) {
                    Log.e(TAG, "tessdata folder not found or not a directory");
                    final String errorMsg = "Tesseract data folder not found. Please reinstall the app.";
                    mainHandler.post(() -> {
                        if (isAdded() && getContext() != null && binding != null) {
                            Toast.makeText(getContext(), "[ERROR] " + errorMsg, Toast.LENGTH_LONG).show();
                            binding.btnRunOcr.setEnabled(false);
                            binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                        }
                    });
                    tessInitialized = false;
                    return;
                }

                // Verify traineddata files exist and are readable (reuse variables from outer scope)
                Log.d(TAG, "Checking mar.traineddata:");
                Log.d(TAG, "  - Exists: " + marFile.exists());
                Log.d(TAG, "  - Size: " + marFile.length() + " bytes");
                Log.d(TAG, "  - Can read: " + marFile.canRead());

                Log.d(TAG, "Checking eng.traineddata:");
                Log.d(TAG, "  - Exists: " + engFile.exists());
                Log.d(TAG, "  - Size: " + engFile.length() + " bytes");
                Log.d(TAG, "  - Can read: " + engFile.canRead());

                // These checks are redundant (already done above) but kept for safety
                if (!marFile.exists() || !engFile.exists()) {
                    Log.e(TAG, "Required traineddata files missing!");
                    Log.e(TAG, "  mar.traineddata exists: " + marFile.exists());
                    Log.e(TAG, "  eng.traineddata exists: " + engFile.exists());
                    final String errorMsg = "Missing OCR language files. Please reinstall the app.";
                    mainHandler.post(() -> {
                        if (isAdded() && getContext() != null && binding != null) {
                            Toast.makeText(getContext(), "[ERROR] " + errorMsg, Toast.LENGTH_LONG).show();
                            binding.btnRunOcr.setEnabled(false);
                            binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                        }
                    });
                    tessInitialized = false;
                    return;
                }

                if (!marFile.canRead() || !engFile.canRead()) {
                    Log.e(TAG, "Traineddata files not readable!");
                    Log.e(TAG, "  mar.traineddata readable: " + marFile.canRead());
                    Log.e(TAG, "  eng.traineddata readable: " + engFile.canRead());
                    final String errorMsg = "OCR language files not accessible. Please reinstall the app.";
                    mainHandler.post(() -> {
                        if (isAdded() && getContext() != null && binding != null) {
                            Toast.makeText(getContext(), "[ERROR] " + errorMsg, Toast.LENGTH_LONG).show();
                            binding.btnRunOcr.setEnabled(false);
                            binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                        }
                    });
                    tessInitialized = false;
                    return;
                }

                // Verify file sizes are reasonable (not corrupted/empty)
                if (marFile.length() < 1000 || engFile.length() < 1000) {
                    Log.e(TAG, "Traineddata files appear corrupted (too small)");
                    Log.e(TAG, "  mar.traineddata size: " + marFile.length());
                    Log.e(TAG, "  eng.traineddata size: " + engFile.length());
                    final String errorMsg = "OCR language files corrupted. Please reinstall the app.";
                    mainHandler.post(() -> {
                        if (isAdded() && getContext() != null && binding != null) {
                            Toast.makeText(getContext(), "[ERROR] " + errorMsg, Toast.LENGTH_LONG).show();
                            binding.btnRunOcr.setEnabled(false);
                            binding.btnRunOcr.setText("[ERROR] OCR Not Available");
                        }
                    });
                    tessInitialized = false;
                    return;
                }

                // Initialize with Marathi + English for bilingual OCR
                Log.d(TAG, "=== Calling tessAPI.init() ===");
                Log.d(TAG, "Parameters:");
                Log.d(TAG, "  dataPath: " + dataPath);
                Log.d(TAG, "  language: mar+eng");
                Log.d(TAG, "  Expected file 1: " + dataPath + "/tessdata/mar.traineddata");
                Log.d(TAG, "  Expected file 2: " + dataPath + "/tessdata/eng.traineddata");

                boolean success = false;
                String errorMessage = null;

                try {
                    Log.d(TAG, "Calling tessAPI.init()...");
                    long startTime = System.currentTimeMillis();

                    success = tessAPI.init(dataPath, "mar+eng");

                    long endTime = System.currentTimeMillis();
                    long duration = endTime - startTime;

                    Log.d(TAG, "tessAPI.init() completed in " + duration + "ms");
                    Log.d(TAG, "tessAPI.init() returned: " + success);

                    if (!success) {
                        errorMessage = "Tesseract init() returned false. Traineddata files may be invalid or corrupted.";
                        Log.e(TAG, "=== INITIALIZATION FAILED ===");
                        Log.e(TAG, errorMessage);
                        Log.e(TAG, "Possible causes:");
                        Log.e(TAG, "  1. Traineddata files are corrupted");
                        Log.e(TAG, "  2. Incompatible Tesseract version");
                        Log.e(TAG, "  3. Insufficient memory");
                        Log.e(TAG, "  4. Incorrect dataPath (should be parent of tessdata/)");
                    } else {
                        Log.d(TAG, "=== INITIALIZATION SUCCESSFUL ===");
                        Log.d(TAG, "[SUCCESS] Tesseract initialized successfully!");
                        Log.d(TAG, "Tesseract is ready for OCR processing");
                    }
                } catch (UnsatisfiedLinkError linkError) {
                    errorMessage = "Native library error during init: " + linkError.getMessage();
                    Log.e(TAG, "=== NATIVE LIBRARY ERROR ===");
                    Log.e(TAG, errorMessage, linkError);
                    Log.e(TAG, "This indicates a problem with the native Tesseract library");
                    success = false;
                } catch (Exception initException) {
                    errorMessage = "Tesseract init() exception: " + initException.getMessage();
                    Log.e(TAG, "=== INITIALIZATION EXCEPTION ===");
                    Log.e(TAG, errorMessage, initException);
                    Log.e(TAG, "Exception class: " + initException.getClass().getName());
                    if (initException.getCause() != null) {
                        Log.e(TAG, "Cause: " + initException.getCause().getMessage());
                    }
                    success = false;
                }

                // CRITICAL: Clean up resources if initialization failed
                if (!success) {
                    Log.e(TAG, "Initialization failed. Cleaning up resources...");
                    try {
                        if (tessAPI != null) {
                            tessAPI.end();
                            Log.d(TAG, "Called tessAPI.end() to release native resources");
                        }
                    } catch (Exception cleanupException) {
                        Log.e(TAG, "Exception during cleanup: " + cleanupException.getMessage(), cleanupException);
                    }
                    tessAPI = null;
                    Log.d(TAG, "Set tessAPI = null to prevent further usage");
                }

                tessInitialized = success;
                Log.d(TAG, "=== Tesseract initialization complete. Result: " + success + " ===");

                final boolean initSuccess = success;
                final String finalErrorMessage = errorMessage;
                mainHandler.post(() -> {
                    if (!isAdded() || getContext() == null || binding == null) {
                        Log.w(TAG, "Fragment not attached, skipping UI update");
                        return;
                    }
                    if (initSuccess) {
                        Toast.makeText(getContext(), "[OK] Tesseract ready for OCR", Toast.LENGTH_SHORT).show();
                        Log.d(TAG, "[OK] UI updated - OCR button enabled");
                        binding.btnRunOcr.setEnabled(true);
                    } else {
                        String msg = finalErrorMessage != null ? finalErrorMessage : "Tesseract initialization failed";
                        Toast.makeText(getContext(), "[ERROR] " + msg, Toast.LENGTH_LONG).show();
                        Log.e(TAG, "[ERROR] UI updated - OCR button disabled");
                        binding.btnRunOcr.setEnabled(false);
                        binding.btnRunOcr.setText("[ERROR] OCR Init Failed");
                    }
                });
            } catch (Exception e) {
                Log.e(TAG, "=== FATAL: Tesseract initialization crashed ===");
                Log.e(TAG, "Exception: " + e.getMessage(), e);
                Log.e(TAG, "Exception class: " + e.getClass().getName());
                if (e.getCause() != null) {
                    Log.e(TAG, "Cause: " + e.getCause().getMessage());
                }
                tessInitialized = false;
                mainHandler.post(() -> {
                    if (isAdded() && getContext() != null && binding != null) {
                        Toast.makeText(getContext(), "[ERROR] OCR initialization crashed: " + e.getMessage(), Toast.LENGTH_LONG).show();
                        binding.btnRunOcr.setEnabled(false);
                        binding.btnRunOcr.setText("[ERROR] OCR Error");
                    }
                });
            }
        });
    }

    private void runOcrOnAllPages() {
        // ✅ GUARD 1: Check if pages exist FIRST (before initializing Tesseract)
        List<PageData> pages = sharedViewModel.getPages().getValue();
        if (pages == null || pages.isEmpty()) {
            if (getContext() != null) {
                Toast.makeText(getContext(),
                        "[WARNING] No pages to process!\n\n1. Go to Scan tab\n2. Scan some pages\n3. Come back here and click Run OCR",
                        Toast.LENGTH_LONG).show();
            }
            return;
        }

        // ✅ GUARD 2: Initialize Tesseract lazily (only when user clicks "Run OCR")
        if (!tessInitialized || tessAPI == null) {
            Log.d(TAG, "Tesseract not initialized. Initializing now...");

            if (getContext() != null) {
                Toast.makeText(getContext(), "[INFO] Initializing OCR engine. Please wait...", Toast.LENGTH_SHORT).show();
            }

            // Initialize Tesseract now
            initTesseract();

            // ✅ FIX: Wait up to 5 seconds for initialization to complete
            // Tesseract initialization can take 1-3 seconds on most devices
            int maxWaitTime = 5000; // 5 seconds
            int waitInterval = 200; // Check every 200ms
            int totalWaited = 0;

            while (totalWaited < maxWaitTime) {
                try {
                    Thread.sleep(waitInterval);
                    totalWaited += waitInterval;

                    // Check if initialization completed (success or failure)
                    if (tessInitialized && tessAPI != null) {
                        Log.d(TAG, "Tesseract initialized successfully after " + totalWaited + "ms");
                        break;
                    }

                    // If tessInitialized is explicitly set to false, initialization failed
                    // (This happens when file checks fail or init() returns false)
                    // We can detect this by checking if the background thread has finished
                    // For now, we'll just wait the full time
                } catch (InterruptedException e) {
                    Log.e(TAG, "Sleep interrupted: " + e.getMessage());
                    break;
                }
            }

            // ✅ CRITICAL: Re-check after waiting
            if (!tessInitialized || tessAPI == null) {
                Log.e(TAG, "Tesseract initialization failed or timed out after " + totalWaited + "ms");
                if (getContext() != null) {
                    Toast.makeText(getContext(),
                            "[ERROR] OCR initialization failed. Check if language files are installed.",
                            Toast.LENGTH_LONG).show();
                }
                return; // ✅ EXIT - do NOT proceed with OCR
            }

            Log.d(TAG, "Tesseract is ready. Proceeding with OCR...");
        }

        // ✅ CRITICAL: Final safety check before proceeding with OCR
        if (tessAPI == null) {
            Log.e(TAG, "CRITICAL: tessAPI is null even after initialization. Cannot proceed.");
            if (getContext() != null) {
                Toast.makeText(getContext(),
                        "[ERROR] OCR engine is not available. Please restart the app.",
                        Toast.LENGTH_LONG).show();
            }
            return;
        }

        Log.d(TAG, "Starting OCR on " + pages.size() + " pages");

        mainHandler.post(() -> {
            if (binding != null) {
                binding.btnRunOcr.setText("Processing...");
                binding.btnRunOcr.setEnabled(false);
            }
        });

        executorService.execute(() -> {
            // ✅ GUARD: Double-check tessAPI is not null inside background thread
            if (tessAPI == null) {
                Log.e(TAG, "tessAPI became null in background thread. Aborting OCR.");
                mainHandler.post(() -> {
                    if (binding != null) {
                        binding.btnRunOcr.setText("Run OCR (Marathi + English)");
                        binding.btnRunOcr.setEnabled(true);
                    }
                    if (getContext() != null) {
                        Toast.makeText(getContext(),
                                "[ERROR] OCR engine unavailable. Please restart the app.",
                                Toast.LENGTH_LONG).show();
                    }
                });
                return;
            }

            List<OcrPageData> ocrResults = new ArrayList<>();

            for (int i = 0; i < pages.size(); i++) {
                final int pageIndex = i;
                PageData page = pages.get(i);

                Log.d(TAG, "Processing page " + (i + 1) + ": " + page.uri);

                mainHandler.post(() -> {
                    if (binding != null) {
                        binding.textPagesCount.setText("Processing page " + (pageIndex + 1) + "/" + pages.size());
                    }
                });

                try {
                    OcrPageData result = processPage(page, pageIndex + 1);
                    ocrResults.add(result);

                    Log.d(TAG, "Page " + (i + 1) + " result: " +
                            (result.ocrText != null ? result.ocrText.substring(0, Math.min(50, result.ocrText.length())) : "null"));

                    Thread.sleep(300); // Small delay for UI update
                } catch (Exception e) {
                    Log.e(TAG, "Error processing page " + (i + 1) + ": " + e.getMessage(), e);
                    OcrPageData errorResult = new OcrPageData();
                    errorResult.ocrText = "[ERROR] OCR Error on page " + (i + 1) + ": " + e.getMessage();
                    errorResult.status = "Failed";
                    ocrResults.add(errorResult);
                }
            }

            final List<OcrPageData> finalResults = ocrResults;
            mainHandler.post(() -> {
                if (binding == null || getContext() == null) {
                    Log.w(TAG, "Fragment not attached, skipping UI update");
                    return;
                }
                adapter.updateOcrData(finalResults.toArray(new OcrPageData[0]));
                binding.btnRunOcr.setText("[OK] OCR Complete");
                binding.btnRunOcr.setEnabled(true);
                binding.textPagesCount.setText("[OK] OCR Ready: " + finalResults.size() + " pages");
                Toast.makeText(getContext(),
                        "[OK] OCR completed!\n" + finalResults.size() + " pages processed",
                        Toast.LENGTH_SHORT).show();
            });
        });
    }

    private OcrPageData processPage(PageData page, int pageNumber) {
        OcrPageData result = new OcrPageData();
        Bitmap bitmap = null;

        try {
            // Load bitmap from content URI (from ML Kit scanner)
            if (page.uri != null && !page.uri.isEmpty()) {
                Uri uri = Uri.parse(page.uri);

                Log.d(TAG, "Loading image from URI: " + page.uri);

                // Handle both content:// and file:// URIs
                if (page.uri.startsWith("content://")) {
                    // Content URI from ML Kit scanner
                    android.content.Context context = getContext();
                    if (context != null) {
                        InputStream inputStream = context.getContentResolver().openInputStream(uri);
                        if (inputStream != null) {
                            bitmap = BitmapFactory.decodeStream(inputStream);
                            inputStream.close();
                        }
                    } else {
                        Log.e(TAG, "Context is null, cannot load image");
                        result.ocrText = "[ERROR] Error: Cannot access image (context unavailable)";
                        result.status = "Failed";
                        return result;
                    }
                } else {
                    // File path
                    File imageFile = new File(page.uri);
                    if (imageFile.exists()) {
                        bitmap = BitmapFactory.decodeFile(page.uri);

                        // Handle image rotation based on EXIF
                        try {
                            ExifInterface exif = new ExifInterface(page.uri);
                            int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
                            bitmap = rotateBitmap(bitmap, orientation);
                        } catch (Exception e) {
                            Log.w(TAG, "Could not read EXIF data: " + e.getMessage());
                        }
                    } else {
                        Log.e(TAG, "File does not exist: " + page.uri);
                        result.ocrText = "[ERROR] Error: Image file not found";
                        result.status = "Failed";
                        return result;
                    }
                }
            }

            if (bitmap != null) {
                Log.d(TAG, "Bitmap loaded. Size: " + bitmap.getWidth() + "x" + bitmap.getHeight());

                // Optimize bitmap size for OCR (max 2000px on longest side)
                bitmap = optimizeBitmapForOCR(bitmap);

                // ✅ CRITICAL: Check tessAPI is not null before using it
                if (tessAPI == null) {
                    Log.e(TAG, "CRITICAL: tessAPI is null in processPage(). Cannot run OCR.");
                    result.ocrText = "[ERROR] OCR engine unavailable. Please restart the app.";
                    result.status = "Failed";
                    bitmap.recycle();
                    return result;
                }

                // Run OCR with page segmentation mode optimized for printed documents
                // PSM 1 = Automatic page segmentation with OSD (Orientation and Script Detection)
                // PSM 3 = Fully automatic page segmentation, but no OSD (default)
                // PSM 6 = Assume a single uniform block of text (best for preserving layout)
                tessAPI.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO); // PSM 3 - preserves structure
                tessAPI.setImage(bitmap);
                String extractedText = tessAPI.getUTF8Text();

                if (extractedText != null && !extractedText.trim().isEmpty()) {
                    result.ocrText = extractedText.trim();
                    result.status = "[OK] Complete (" + extractedText.length() + " chars)";
                    Log.d(TAG, "[OK] Page " + pageNumber + ": Extracted " + extractedText.length() + " characters");
                } else {
                    result.ocrText = "[WARNING] No text detected in this image.\n\nTips:\n- Ensure good lighting\n- Text should be clear and in focus\n- Try rescanning the page";
                    result.status = "Empty";
                    Log.w(TAG, "[WARNING] Page " + pageNumber + ": OCR returned empty text");
                }

                bitmap.recycle();
            } else {
                Log.e(TAG, "Failed to load bitmap from: " + page.uri);
                result.ocrText = "[ERROR] Error: Could not load image from URI";
                result.status = "Failed";
            }

        } catch (Exception e) {
            Log.e(TAG, "Exception processing page " + pageNumber + ": " + e.getMessage(), e);
            result.ocrText = "[ERROR] Error processing page: " + e.getMessage();
            result.status = "Failed";
            if (bitmap != null) {
                bitmap.recycle();
            }
        }

        return result;
    }

    private Bitmap optimizeBitmapForOCR(Bitmap original) {
        int maxSize = 2000;
        int width = original.getWidth();
        int height = original.getHeight();

        if (width <= maxSize && height <= maxSize) {
            return original;
        }

        float scale = Math.min((float) maxSize / width, (float) maxSize / height);
        int newWidth = Math.round(width * scale);
        int newHeight = Math.round(height * scale);

        Bitmap scaled = Bitmap.createScaledBitmap(original, newWidth, newHeight, true);
        if (scaled != original) {
            original.recycle();
        }

        return scaled;
    }

    /**
     * Process OCR text with preserved formatting and structure
     * Creates separate paragraphs for each line/block with intelligent spacing
     */
    private void processTextWithFormatting(XWPFDocument document, String text) {
        if (text == null || text.isEmpty()) {
            return;
        }

        // Split text into lines (preserve original line breaks from OCR)
        String[] lines = text.split("\n");

        int consecutiveEmptyLines = 0;

        for (int i = 0; i < lines.length; i++) {
            String line = lines[i].trim();

            // Track empty lines for paragraph spacing
            if (line.isEmpty()) {
                consecutiveEmptyLines++;
                continue;
            }

            // Create paragraph for this line
            XWPFParagraph para = document.createParagraph();

            // Set line spacing for Devanagari readability (1.5 line spacing)
            para.setSpacingBetween(1.5, LineSpacingRule.AUTO);

            // Add spacing before paragraph if there were empty lines
            if (consecutiveEmptyLines > 0) {
                // More empty lines = more spacing (max 300 twips = 15pt)
                int spacing = Math.min(consecutiveEmptyLines * 150, 300);
                para.setSpacingBefore(spacing);
            }

            // Detect if this line is likely a heading
            boolean isHeading = detectHeading(line, i, lines);

            // Detect alignment (center for short lines that look like titles)
            ParagraphAlignment alignment = detectAlignment(line, isHeading);
            para.setAlignment(alignment);

            // Write text with explicit word-by-word spacing to preserve spaces in Word
            String normalizedLine = normalizeOcrTextForDocx(line);

            // Apply formatting based on line type
            if (isHeading) {
                writeTextWithExplicitSpacing(para, normalizedLine, "Noto Sans Devanagari", 14, true);
                para.setSpacingAfter(100); // Extra spacing after headings
            } else {
                writeTextWithExplicitSpacing(para, normalizedLine, "Noto Sans Devanagari", 11, false);
                para.setSpacingAfter(50); // Small spacing between lines
            }

            consecutiveEmptyLines = 0; // Reset counter
        }
    }

    /**
     * Detect if a line is likely a heading based on:
     * - Length (short lines are often headings)
     * - Position (first few lines of page)
     * - All caps or title case
     */
    private boolean detectHeading(String line, int lineIndex, String[] allLines) {
        if (line.isEmpty()) return false;

        // First 3 non-empty lines are more likely to be headings
        boolean isEarlyLine = lineIndex < 3;

        // Short lines (< 50 chars) are more likely to be headings
        boolean isShort = line.length() < 50;

        // Check if line is all uppercase (common for headings)
        boolean isAllCaps = line.equals(line.toUpperCase()) && line.matches(".*[A-Z\u0900-\u097F].*");

        // Check if line ends with colon (common for section headers)
        boolean endsWithColon = line.endsWith(":");

        // Heading detection logic
        if (isAllCaps && isShort) return true;
        if (isEarlyLine && isShort) return true;
        if (endsWithColon && isShort) return true;

        return false;
    }

    /**
     * Detect text alignment based on line characteristics
     * - Short lines that look like titles → CENTER
     * - Everything else → LEFT
     */
    private ParagraphAlignment detectAlignment(String line, boolean isHeading) {
        // Very short lines (< 30 chars) that are headings → center
        if (isHeading && line.length() < 30) {
            return ParagraphAlignment.CENTER;
        }

        // Default to left alignment
        return ParagraphAlignment.LEFT;
    }

    private Bitmap rotateBitmap(Bitmap bitmap, int orientation) {
        Matrix matrix = new Matrix();
        switch (orientation) {
            case ExifInterface.ORIENTATION_ROTATE_90:
                matrix.postRotate(90);
                break;
            case ExifInterface.ORIENTATION_ROTATE_180:
                matrix.postRotate(180);
                break;
            case ExifInterface.ORIENTATION_ROTATE_270:
                matrix.postRotate(270);
                break;
            default:
                return bitmap;
        }

        Bitmap rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
        if (rotated != bitmap) {
            bitmap.recycle();
        }
        return rotated;
    }

    private void exportWord() {
        // Check if OCR has been run
        List<OcrPageData> ocrData = adapter.getOcrData();
        if (ocrData == null || ocrData.isEmpty()) {
            if (getContext() != null) {
                Toast.makeText(getContext(),
                        "[WARNING] No OCR data available!\n\nSteps:\n1. Go to Scan tab\n2. Scan pages\n3. Return here\n4. Click 'Run OCR'\n5. Then export",
                        Toast.LENGTH_LONG).show();
            }
            return;
        }

        // Check for Android 10+ or legacy storage permission
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q || checkPermission()) {
            exportWordDocument();
        } else {
            requestStoragePermission();
        }
    }

    private void exportWordDocument() {
        // Capture context before background thread
        final android.content.Context context = getContext();
        if (context == null) {
            Log.e(TAG, "Context is null, cannot export");
            return;
        }

        mainHandler.post(() -> {
            if (binding != null) {
                binding.btnExportWord.setText("Exporting...");
                binding.btnExportWord.setEnabled(false);
            }
        });

        executorService.execute(() -> {
            File resultFile = null;
            try {
                List<OcrPageData> ocrData = adapter.getOcrData();

                Log.d(TAG, "Exporting " + ocrData.size() + " pages to DOCX");

                // Create DOCX document with A4 page configuration
                XWPFDocument document = new XWPFDocument();
                configureA4PageSettings(document);

                // Title page
                XWPFParagraph title = document.createParagraph();
                title.setAlignment(ParagraphAlignment.CENTER);
                title.setSpacingBetween(1.5, LineSpacingRule.AUTO); // Line spacing for readability
                XWPFRun titleRun = title.createRun();
                titleRun.setText(normalizeOcrTextForDocx("OCR Extracted Document"));
                titleRun.setBold(true);
                titleRun.setFontSize(20);
                titleRun.setFontFamily("Noto Sans Devanagari");
                titleRun.addBreak();

                XWPFRun subtitle = title.createRun();
                subtitle.setText(normalizeOcrTextForDocx("Generated by ScanDoc"));
                subtitle.setFontSize(12);
                subtitle.setItalic(true);
                subtitle.setFontFamily("Noto Sans Devanagari");
                subtitle.addBreak();
                subtitle.addBreak();

                // Add each OCR page with preserved formatting
                int successfulPages = 0;
                for (int i = 0; i < ocrData.size(); i++) {
                    // Page header with separator
                    XWPFParagraph pagePara = document.createParagraph();
                    pagePara.setAlignment(ParagraphAlignment.CENTER);
                    pagePara.setSpacingBetween(1.5, LineSpacingRule.AUTO); // Line spacing for readability
                    pagePara.setSpacingBefore(200); // 10pt spacing before
                    pagePara.setSpacingAfter(200);  // 10pt spacing after
                    XWPFRun pageRun = pagePara.createRun();
                    pageRun.setText(normalizeOcrTextForDocx("─────── Page " + (i + 1) + " ───────"));
                    pageRun.setBold(true);
                    pageRun.setFontSize(14);
                    pageRun.setFontFamily("Noto Sans Devanagari");

                    String text = ocrData.get(i).ocrText;

                    if (text != null && !text.isEmpty() && !text.startsWith("[WARNING]") && !text.startsWith("[ERROR]")) {
                        // Process text with preserved formatting
                        processTextWithFormatting(document, text);
                        successfulPages++;
                        Log.d(TAG, "Page " + (i + 1) + " exported: " + text.length() + " characters");
                    } else if (text != null && text.startsWith("[WARNING]")) {
                        XWPFParagraph emptyPara = document.createParagraph();
                        emptyPara.setSpacingBetween(1.5, LineSpacingRule.AUTO); // Line spacing for readability
                        XWPFRun emptyRun = emptyPara.createRun();
                        emptyRun.setText(normalizeOcrTextForDocx("[No text detected on this page]"));
                        emptyRun.setItalic(true);
                        emptyRun.setFontFamily("Noto Sans Devanagari");
                        emptyRun.setFontSize(11);
                        Log.w(TAG, "Page " + (i + 1) + " had no text");
                    } else if (text != null && text.startsWith("[ERROR]")) {
                        XWPFParagraph errorPara = document.createParagraph();
                        errorPara.setSpacingBetween(1.5, LineSpacingRule.AUTO); // Line spacing for readability
                        XWPFRun errorRun = errorPara.createRun();
                        errorRun.setText(normalizeOcrTextForDocx("[Error processing this page]"));
                        errorRun.setItalic(true);
                        errorRun.setFontFamily("Noto Sans Devanagari");
                        errorRun.setFontSize(11);
                        Log.e(TAG, "Page " + (i + 1) + " had error");
                    } else {
                        XWPFParagraph emptyPara = document.createParagraph();
                        emptyPara.setSpacingBetween(1.5, LineSpacingRule.AUTO); // Line spacing for readability
                        XWPFRun emptyRun = emptyPara.createRun();
                        emptyRun.setText(normalizeOcrTextForDocx("[Empty page]"));
                        emptyRun.setItalic(true);
                        emptyRun.setFontFamily("Noto Sans Devanagari");
                        emptyRun.setFontSize(11);
                    }

                    // Add page break after each page (except last)
                    if (i < ocrData.size() - 1) {
                        XWPFParagraph pageBreak = document.createParagraph();
                        pageBreak.setPageBreak(true);
                    }
                }

                // Save file to PUBLIC Documents folder (accessible in any file manager)
                File dir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "ScanDoc");

                if (!dir.exists()) {
                    dir.mkdirs();
                }

                String filename = "ScanDoc_OCR_" + System.currentTimeMillis() + ".docx";
                File file = new File(dir, filename);

                FileOutputStream out = new FileOutputStream(file);
                document.write(out);
                out.close();
                document.close();

                resultFile = file;
                Log.d(TAG, "[OK] DOCX saved: " + file.getAbsolutePath());

                final int finalSuccessfulPages = successfulPages;
                File finalResultFile = resultFile;
                mainHandler.post(() -> {
                    if (binding == null || getContext() == null) {
                        Log.w(TAG, "Fragment not attached, skipping Toast");
                        return;
                    }
                    binding.btnExportWord.setText("Export Word DOCX");
                    binding.btnExportWord.setEnabled(true);

                    if (finalResultFile != null) {
                        Toast.makeText(getContext(),
                                "[OK] DOCX exported!\n\n" +
                                        "Pages with text: " + finalSuccessfulPages + "/" + ocrData.size() + "\n\n" +
                                        "Location: Documents/ScanDoc/\n" +
                                        "File: " + finalResultFile.getName() + "\n\n" +
                                        "Open 'Files' app → Documents → ScanDoc",
                                Toast.LENGTH_LONG).show();
                    }
                });

            } catch (Exception e) {
                Log.e(TAG, "Export error: " + e.getMessage(), e);
                final String errorMsg = e.getMessage();
                mainHandler.post(() -> {
                    if (binding == null || getContext() == null) {
                        Log.w(TAG, "Fragment not attached, skipping error Toast");
                        return;
                    }
                    binding.btnExportWord.setText("Export Word DOCX");
                    binding.btnExportWord.setEnabled(true);
                    Toast.makeText(getContext(), "[ERROR] Export failed: " + errorMsg, Toast.LENGTH_LONG).show();
                });
            }
        });
    }

    private void exportPdf() {
        // Temporarily use this button for UTF-8 text export
        exportText();
    }

    private void exportText() {
        // Check if OCR has been run
        List<OcrPageData> ocrData = adapter.getOcrData();
        if (ocrData == null || ocrData.isEmpty()) {
            if (getContext() != null) {
                Toast.makeText(getContext(),
                        "[WARNING] No OCR data available!\n\nSteps:\n1. Go to Scan tab\n2. Scan pages\n3. Return here\n4. Click 'Run OCR'\n5. Then export",
                        Toast.LENGTH_LONG).show();
            }
            return;
        }

        // Check for Android 10+ or legacy storage permission
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q || checkPermission()) {
            exportTextDocument();
        } else {
            requestStoragePermission();
        }
    }

    private void exportTextDocument() {
        // Capture context before background thread
        final android.content.Context context = getContext();
        if (context == null) {
            Log.e(TAG, "Context is null, cannot export");
            return;
        }

        mainHandler.post(() -> {
            if (binding != null) {
                binding.btnExportPdf.setText("Exporting...");
                binding.btnExportPdf.setEnabled(false);
            }
        });

        executorService.execute(() -> {
            File resultFile = null;
            try {
                List<OcrPageData> ocrData = adapter.getOcrData();

                Log.d(TAG, "Exporting " + ocrData.size() + " pages to TXT");

                // Build text content
                StringBuilder textContent = new StringBuilder();
                textContent.append("═══════════════════════════════════════\n");
                textContent.append("  OCR EXTRACTED DOCUMENT\n");
                textContent.append("  Generated by ScanDoc\n");
                textContent.append("═══════════════════════════════════════\n\n");

                int successfulPages = 0;
                for (int i = 0; i < ocrData.size(); i++) {
                    textContent.append("─────── Page ").append(i + 1).append(" ───────\n\n");

                    String text = ocrData.get(i).ocrText;
                    if (text != null && !text.isEmpty() && !text.startsWith("[WARNING]") && !text.startsWith("[ERROR]")) {
                        textContent.append(text);
                        successfulPages++;
                        Log.d(TAG, "Page " + (i + 1) + " exported: " + text.length() + " characters");
                    } else if (text != null && text.startsWith("[WARNING]")) {
                        textContent.append("[No text detected on this page]");
                        Log.w(TAG, "Page " + (i + 1) + " had no text");
                    } else if (text != null && text.startsWith("[ERROR]")) {
                        textContent.append("[Error processing this page]");
                        Log.e(TAG, "Page " + (i + 1) + " had error");
                    } else {
                        textContent.append("[Empty page]");
                    }

                    textContent.append("\n\n");
                }

                // Save file with explicit UTF-8 encoding
                File dir;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    dir = new File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), "ScanDoc");
                } else {
                    dir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "ScanDoc");
                }

                if (!dir.exists()) {
                    dir.mkdirs();
                }

                String filename = "ScanDoc_OCR_" + System.currentTimeMillis() + ".txt";
                File file = new File(dir, filename);

                // Use OutputStreamWriter with explicit UTF-8 charset
                FileOutputStream fos = new FileOutputStream(file);
                OutputStreamWriter writer = new OutputStreamWriter(fos, StandardCharsets.UTF_8);
                writer.write(textContent.toString());
                writer.flush();
                writer.close();
                fos.close();

                resultFile = file;
                Log.d(TAG, "[OK] TXT saved: " + file.getAbsolutePath());

                final int finalSuccessfulPages = successfulPages;
                File finalResultFile = resultFile;
                mainHandler.post(() -> {
                    if (binding == null || getContext() == null) {
                        Log.w(TAG, "Fragment not attached, skipping Toast");
                        return;
                    }
                    binding.btnExportPdf.setText("Export UTF-8 Text");
                    binding.btnExportPdf.setEnabled(true);

                    if (finalResultFile != null) {
                        Toast.makeText(getContext(),
                                "[OK] Text file exported!\n\n" +
                                        "Pages with text: " + finalSuccessfulPages + "/" + ocrData.size() + "\n\n" +
                                        "Location:\n" + file.getAbsolutePath(),
                                Toast.LENGTH_LONG).show();
                    }
                });

            } catch (Exception e) {
                Log.e(TAG, "Export error: " + e.getMessage(), e);
                final String errorMsg = e.getMessage();
                mainHandler.post(() -> {
                    if (binding == null || getContext() == null) {
                        Log.w(TAG, "Fragment not attached, skipping error Toast");
                        return;
                    }
                    binding.btnExportPdf.setText("Export UTF-8 Text");
                    binding.btnExportPdf.setEnabled(true);
                    Toast.makeText(getContext(), "[ERROR] Export failed: " + errorMsg, Toast.LENGTH_LONG).show();
                });
            }
        });
    }

    private void exportDtp() {
        if (getContext() != null) {
            Toast.makeText(getContext(), "DTP Export (Coming soon)", Toast.LENGTH_SHORT).show();
        }
    }

    private boolean checkPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            return true;
        }
        android.content.Context context = getContext();
        if (context == null) {
            return false;
        }
        return ContextCompat.checkSelfPermission(context,
                Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestStoragePermission() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.Q) {
            ActivityCompat.requestPermissions(requireActivity(),
                    new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},
                    STORAGE_PERMISSION_CODE);
        }
    }

    private void observeData() {
        sharedViewModel.getPages().observe(getViewLifecycleOwner(), pages -> {
            int pageCount = (pages != null ? pages.size() : 0);
            binding.textPagesCount.setText("Total Pages: " + pageCount);

            // ✅ FIX: Disable OCR button when no pages exist
            if (pageCount == 0) {
                Log.d(TAG, "No pages available - disabling OCR button");
                binding.btnRunOcr.setEnabled(false);
                binding.btnRunOcr.setText("No Pages Available");

                // Also disable export buttons
                binding.btnExportWord.setEnabled(false);
                binding.btnExportPdf.setEnabled(false);
                binding.btnExportDtp.setEnabled(false);
            } else {
                Log.d(TAG, "Pages updated: " + pageCount + " pages available");

                // Enable Run OCR button
                binding.btnRunOcr.setEnabled(true);
                binding.btnRunOcr.setText("Run OCR (Marathi + English)");

                // Export buttons remain disabled until OCR is run
                // (They will be enabled by the OCR completion handler)

                for (int i = 0; i < Math.min(3, pages.size()); i++) {
                    Log.d(TAG, "  Page " + (i + 1) + ": " + pages.get(i).uri);
                }
            }
        });
    }

    @Override
    public void onDestroy() {
        if (tessAPI != null) {
            tessAPI.end();
        }
        if (executorService != null) {
            executorService.shutdown();
        }
        super.onDestroy();
    }

    /**
     * Normalize OCR text for DOCX export
     * Fixes word spacing issues caused by non-standard Unicode whitespace characters
     *
     * @param rawText Raw OCR text from Tesseract
     * @return Normalized text with consistent word spacing
     */
    private String normalizeOcrTextForDocx(String rawText) {
        if (rawText == null || rawText.isEmpty()) {
            return rawText;
        }

        String normalized = rawText;

        // Replace non-breaking spaces (U+00A0) with regular ASCII space (U+0020)
        normalized = normalized.replace('\u00A0', ' ');

        // Remove zero-width joiner (U+200D) - can interfere with word boundaries
        normalized = normalized.replace("\u200D", "");

        // Remove zero-width non-joiner (U+200C) - can interfere with word boundaries
        normalized = normalized.replace("\u200C", "");

        // Remove zero-width space (U+200B)
        normalized = normalized.replace("\u200B", "");

        // Collapse multiple consecutive spaces into a single space
        // Preserve line breaks by not replacing them
        normalized = normalized.replaceAll("[ \\t]+", " ");

        // Trim leading/trailing whitespace from the entire text
        normalized = normalized.trim();

        return normalized;
    }

    /**
     * Write text to DOCX paragraph with EXPLICIT word-by-word spacing
     * This ensures Microsoft Word preserves visible spaces between words
     *
     * CRITICAL FIX FOR DEVANAGARI (MARATHI) TEXT:
     * - Each word MUST be written as a SEPARATE CTText node
     * - Each space MUST be written as a SEPARATE CTText node
     * - xml:space="preserve" MUST be set on EVERY CTText node
     * - This forces Word to preserve spaces in Devanagari text
     *
     * ROOT CAUSE: XWPFRun.setText() does NOT set xml:space="preserve"
     * PREVIOUS FAILURE: Writing word+space as single CTText node does NOT work
     * SOLUTION: Use low-level CTR.addNewT() to create SEPARATE CTText nodes for words and spaces
     *
     * @param para XWPFParagraph to write to
     * @param text Normalized text to write
     * @param fontFamily Font family (e.g., "Noto Sans Devanagari")
     * @param fontSize Font size in points
     * @param isBold Whether text should be bold
     */
    private void writeTextWithExplicitSpacing(XWPFParagraph para, String text,
                                               String fontFamily, int fontSize, boolean isBold) {
        if (text == null || text.isEmpty()) {
            return;
        }

        // DIAGNOSTIC: Log the text being processed
        android.util.Log.d("DOCX_EXPORT", "Processing text: [" + text + "]");
        android.util.Log.d("DOCX_EXPORT", "Text length: " + text.length() + " chars");

        // Split text into words (separated by spaces)
        // Use regex to split by one or more whitespace characters
        String[] words = text.split("\\s+");

        android.util.Log.d("DOCX_EXPORT", "Split into " + words.length + " words");
        for (int idx = 0; idx < words.length; idx++) {
            android.util.Log.d("DOCX_EXPORT", "  Word[" + idx + "]: [" + words[idx] + "]");
        }

        // Create a single run for all text in this line
        // This keeps formatting consistent while allowing separate CTText nodes
        XWPFRun run = para.createRun();

        // Apply formatting to the run
        run.setFontFamily(fontFamily);
        run.setFontSize(fontSize);
        if (isBold) {
            run.setBold(true);
        }

        // Get the CTR object for low-level XML manipulation
        CTR ctr = run.getCTR();

        int ctTextCount = 0;
        for (int i = 0; i < words.length; i++) {
            String word = words[i].trim();

            if (word.isEmpty()) {
                continue; // Skip empty words
            }

            // CRITICAL: Create a SEPARATE CTText node for the word (WITHOUT trailing space)
            CTText wordText = ctr.addNewT();
            wordText.setStringValue(word);
            wordText.setSpace(Space.PRESERVE);
            ctTextCount++;
            android.util.Log.d("DOCX_EXPORT", "  Created CTText[" + ctTextCount + "] for word: [" + word + "]");

            // CRITICAL: After each word (except the last), create a SEPARATE CTText node for the space
            if (i < words.length - 1) {
                CTText spaceText = ctr.addNewT();
                spaceText.setStringValue(" ");
                spaceText.setSpace(Space.PRESERVE);
                ctTextCount++;
                android.util.Log.d("DOCX_EXPORT", "  Created CTText[" + ctTextCount + "] for space");
            }
        }

        android.util.Log.d("DOCX_EXPORT", "Total CTText nodes created: " + ctTextCount);
    }

    /**
     * Configure A4 page settings for DOCX document
     * A4 size: 210mm × 297mm
     * Margins: 25mm (approximately 1 inch) on all sides
     */
    private void configureA4PageSettings(XWPFDocument document) {
        CTBody body = document.getDocument().getBody();

        // Get or create section properties
        CTSectPr sectPr = body.isSetSectPr() ? body.getSectPr() : body.addNewSectPr();

        // Configure A4 page size
        CTPageSz pageSize = sectPr.isSetPgSz() ? sectPr.getPgSz() : sectPr.addNewPgSz();

        // A4 dimensions in twips (1 inch = 1440 twips, 1 cm = 567 twips)
        // A4 width: 210mm = 21cm = 21 × 567 = 11907 twips
        // A4 height: 297mm = 29.7cm = 29.7 × 567 = 16838 twips
        pageSize.setW(BigInteger.valueOf(11906)); // 210mm width
        pageSize.setH(BigInteger.valueOf(16838)); // 297mm height

        // Configure margins (25mm = 2.5cm = 2.5 × 567 = 1417 twips)
        CTPageMar pageMar = sectPr.isSetPgMar() ? sectPr.getPgMar() : sectPr.addNewPgMar();

        // Set all margins to 25mm (1417 twips) for A4 standard
        pageMar.setTop(BigInteger.valueOf(1417));    // Top margin: 25mm
        pageMar.setBottom(BigInteger.valueOf(1417)); // Bottom margin: 25mm
        pageMar.setLeft(BigInteger.valueOf(1417));   // Left margin: 25mm
        pageMar.setRight(BigInteger.valueOf(1417));  // Right margin: 25mm

        // Set header and footer margins (smaller)
        pageMar.setHeader(BigInteger.valueOf(708));  // Header: 12.5mm
        pageMar.setFooter(BigInteger.valueOf(708));  // Footer: 12.5mm

        Log.d(TAG, "A4 page settings configured:");
        Log.d(TAG, "  Page size: 210mm × 297mm (11906 × 16838 twips)");
        Log.d(TAG, "  Margins: 25mm (1417 twips) on all sides");
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}