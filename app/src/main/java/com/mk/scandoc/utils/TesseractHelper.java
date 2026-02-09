package com.mk.scandoc.utils;

import android.content.Context;
import android.util.Log;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

/**
 * Helper class to copy Tesseract traineddata files from assets to app's files directory
 * Following tess-two best practices for file structure
 */
public class TesseractHelper {
    private static final String TAG = "TesseractHelper";
    private static final String TESSERACT_FOLDER = "tesseract";
    private static final String TESSDATA_FOLDER = "tessdata";

    /**
     * Copies traineddata files from assets/tessdata to files/tesseract/tessdata
     * This method MUST be called before any OCR initialization
     *
     * @param context Application context
     * @return true if successful, false otherwise
     */
    public static boolean copyTrainedDataIfNeeded(Context context) {
        try {
            Log.d(TAG, "=== copyTrainedDataIfNeeded() START ===");
            Log.d(TAG, "Files directory: " + context.getFilesDir().getAbsolutePath());

            // Create directory structure: <files>/tesseract/tessdata/
            File tesseractDir = new File(context.getFilesDir(), TESSERACT_FOLDER);
            File tessDataDir = new File(tesseractDir, TESSDATA_FOLDER);

            Log.d(TAG, "Target directory: " + tessDataDir.getAbsolutePath());

            if (!tessDataDir.exists()) {
                Log.d(TAG, "Creating directory structure...");
                boolean created = tessDataDir.mkdirs();
                if (!created) {
                    Log.e(TAG, "[ERROR] Failed to create directory: " + tessDataDir.getAbsolutePath());
                    return false;
                }
                Log.d(TAG, "[OK] Directory created: " + tessDataDir.getAbsolutePath());
            } else {
                Log.d(TAG, "Directory already exists: " + tessDataDir.getAbsolutePath());
            }

            // Get list of files in assets/tessdata
            String[] assetFiles = context.getAssets().list(TESSDATA_FOLDER);

            if (assetFiles == null || assetFiles.length == 0) {
                Log.e(TAG, "[CRITICAL] No files found in assets/tessdata");
                return false;
            }

            Log.d(TAG, "Found " + assetFiles.length + " files in assets/tessdata");
            for (String file : assetFiles) {
                Log.d(TAG, "  - " + file);
            }


            // Copy required files: mar.traineddata and eng.traineddata
            String[] requiredFiles = {"mar.traineddata", "eng.traineddata"};

            for (String filename : requiredFiles) {
                File destFile = new File(tessDataDir, filename);

                // ONLY copy if file does NOT exist
                if (destFile.exists()) {
                    Log.d(TAG, "File already exists, skipping: " + filename);
                    Log.d(TAG, "  Path: " + destFile.getAbsolutePath());
                    Log.d(TAG, "  Size: " + destFile.length() + " bytes");
                    continue;
                }

                Log.d(TAG, "Copying " + filename + " from assets...");

                InputStream in = null;
                FileOutputStream out = null;

                try {
                    in = context.getAssets().open(TESSDATA_FOLDER + "/" + filename);
                    out = new FileOutputStream(destFile);

                    // Buffered stream copy (NO available())
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    long totalBytes = 0;

                    while ((bytesRead = in.read(buffer)) != -1) {
                        out.write(buffer, 0, bytesRead);
                        totalBytes += bytesRead;
                    }

                    out.flush();
                    out.getFD().sync();

                    Log.d(TAG, "[OK] Copied " + filename + ": " + totalBytes + " bytes");
                    Log.d(TAG, "  Absolute path: " + destFile.getAbsolutePath());

                } catch (Exception e) {
                    Log.e(TAG, "[ERROR] Failed to copy " + filename + ": " + e.getMessage());
                    throw e;

                } finally {
                    if (in != null) in.close();
                    if (out != null) out.close();
                }
            }


            // Verify files exist AFTER copying
            File marFile = new File(tessDataDir, "mar.traineddata");
            File engFile = new File(tessDataDir, "eng.traineddata");

            Log.d(TAG, "=== Final Verification ===");
            Log.d(TAG, "mar.traineddata:");
            Log.d(TAG, "  Exists: " + marFile.exists());
            Log.d(TAG, "  Path: " + marFile.getAbsolutePath());
            Log.d(TAG, "  Size: " + (marFile.exists() ? marFile.length() : 0) + " bytes");

            Log.d(TAG, "eng.traineddata:");
            Log.d(TAG, "  Exists: " + engFile.exists());
            Log.d(TAG, "  Path: " + engFile.getAbsolutePath());
            Log.d(TAG, "  Size: " + (engFile.exists() ? engFile.length() : 0) + " bytes");

            if (!marFile.exists() || !engFile.exists()) {
                Log.e(TAG, "[ERROR] Required files missing!");
                return false;
            }

            Log.d(TAG, "[SUCCESS] All files ready");
            Log.d(TAG, "=== copyTrainedDataIfNeeded() END ===");
            return true;

        } catch (Exception e) {
            Log.e(TAG, "[ERROR] Exception: " + e.getMessage(), e);
            return false;
        }
    }

    /**
     * Gets the data path for Tesseract initialization
     * This is the PARENT directory of tessdata/
     *
     * @param context Application context
     * @return Path to use for tessAPI.init(dataPath, language)
     */
    public static String getDataPath(Context context) {
        // Return: /data/user/0/com.mk.scandoc/files/tesseract
        // Tesseract will look for: /data/user/0/com.mk.scandoc/files/tesseract/tessdata/
        File tesseractDir = new File(context.getFilesDir(), TESSERACT_FOLDER);
        String dataPath = tesseractDir.getAbsolutePath();
        Log.d(TAG, "getDataPath() returning: " + dataPath);
        return dataPath;
    }

}