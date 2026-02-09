package com.mk.scandoc.ui.scan;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.IntentSenderRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;

import com.google.mlkit.vision.documentscanner.GmsDocumentScanner;
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult;
import com.mk.scandoc.databinding.FragmentScanBinding;
import com.mk.scandoc.ui.files.FilesViewModel;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class ScanFragment extends Fragment {
    private static final String TAG = "ScanFragment";
    private FragmentScanBinding binding;
    private FilesViewModel sharedViewModel;

    private final ActivityResultLauncher<IntentSenderRequest> scannerLauncher =
            registerForActivityResult(new ActivityResultContracts.StartIntentSenderForResult(),
                    result -> {
                        if (result.getResultCode() == Activity.RESULT_OK && result.getData() != null) {
                            GmsDocumentScanningResult scanResult =
                                    GmsDocumentScanningResult.fromActivityResultIntent(result.getData());

                            if (scanResult != null && scanResult.getPages() != null) {
                                processScanResults(scanResult);
                            }
                        }
                    });

    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        ScanViewModel scanViewModel = new ViewModelProvider(this).get(ScanViewModel.class);
        binding = FragmentScanBinding.inflate(inflater, container, false);
        View root = binding.getRoot();

        sharedViewModel = new ViewModelProvider(requireActivity()).get(FilesViewModel.class);

        binding.btnScan.setOnClickListener(v -> openScanner());

        scanViewModel.getText().observe(getViewLifecycleOwner(), binding.textDashboard::setText);
        return root;
    }

    private void openScanner() {
        GmsDocumentScannerOptions options = new GmsDocumentScannerOptions.Builder()
                .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
                .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                .setGalleryImportAllowed(true)
                .setPageLimit(50)  // Allow up to 50 pages
                .build();

        GmsDocumentScanner scanner = GmsDocumentScanning.getClient(options);

        scanner.getStartScanIntent(requireActivity())
                .addOnSuccessListener(intentSender -> {
                    IntentSenderRequest request = new IntentSenderRequest.Builder(intentSender).build();
                    scannerLauncher.launch(request);
                })
                .addOnFailureListener(e ->
                        Toast.makeText(requireContext(), "Scanner error: " + e.getMessage(), Toast.LENGTH_SHORT).show()
                );
    }

    private void processScanResults(GmsDocumentScanningResult scanResult) {
        // Show processing message
        Toast.makeText(requireContext(), "💾 Saving " + scanResult.getPages().size() + " pages...", Toast.LENGTH_SHORT).show();

        // Process in background to avoid blocking UI
        new Thread(() -> {
            int savedCount = 0;
            int failedCount = 0;

            // Create directory for scanned images
            File scanDir = new File(requireContext().getExternalFilesDir(Environment.DIRECTORY_PICTURES), "ScanDoc");
            if (!scanDir.exists()) {
                scanDir.mkdirs();
            }

            Log.d(TAG, "Saving scanned images to: " + scanDir.getAbsolutePath());

            // Save each scanned page
            for (int i = 0; i < scanResult.getPages().size(); i++) {
                try {
                    Uri tempUri = scanResult.getPages().get(i).getImageUri();
                    Log.d(TAG, "Processing page " + (i + 1) + " from temp URI: " + tempUri);

                    // Load bitmap from temporary content URI
                    InputStream inputStream = requireContext().getContentResolver().openInputStream(tempUri);
                    if (inputStream == null) {
                        Log.e(TAG, "Failed to open input stream for page " + (i + 1));
                        failedCount++;
                        continue;
                    }

                    Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
                    inputStream.close();

                    if (bitmap == null) {
                        Log.e(TAG, "Failed to decode bitmap for page " + (i + 1));
                        failedCount++;
                        continue;
                    }

                    Log.d(TAG, "Bitmap loaded: " + bitmap.getWidth() + "x" + bitmap.getHeight());

                    // Save to permanent location
                    String filename = "scan_" + System.currentTimeMillis() + "_page" + (i + 1) + ".jpg";
                    File permanentFile = new File(scanDir, filename);

                    FileOutputStream fos = new FileOutputStream(permanentFile);
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
                    fos.flush();
                    fos.close();
                    bitmap.recycle();

                    Log.d(TAG, "✅ Saved page " + (i + 1) + " to: " + permanentFile.getAbsolutePath());

                    // Add to ViewModel with permanent file path
                    String permanentPath = permanentFile.getAbsolutePath();
                    requireActivity().runOnUiThread(() -> {
                        sharedViewModel.addPage(permanentPath, "Ready");
                    });

                    savedCount++;

                } catch (Exception e) {
                    Log.e(TAG, "Error saving page " + (i + 1) + ": " + e.getMessage(), e);
                    failedCount++;
                }
            }

            // Show result
            final int finalSaved = savedCount;
            final int finalFailed = failedCount;
            requireActivity().runOnUiThread(() -> {
                if (finalSaved > 0) {
                    Toast.makeText(requireContext(),
                            "✅ Saved " + finalSaved + " page(s) successfully!" +
                                    (finalFailed > 0 ? "\n⚠️ " + finalFailed + " failed" : ""),
                            Toast.LENGTH_LONG).show();
                    Log.d(TAG, "Total saved: " + finalSaved + ", failed: " + finalFailed);
                } else {
                    Toast.makeText(requireContext(),
                            "❌ Failed to save pages. Please try again.",
                            Toast.LENGTH_LONG).show();
                }
            });
        }).start();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}