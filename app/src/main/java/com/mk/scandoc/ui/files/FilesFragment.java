package com.mk.scandoc.ui.files;

import android.Manifest;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.navigation.Navigation;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.mk.scandoc.R;
import com.mk.scandoc.databinding.FragmentFilesBinding;
import com.mk.scandoc.utils.DocumentProcessor;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class FilesFragment extends Fragment {
    private static final String TAG = "FilesFragment";
    private FragmentFilesBinding binding;
    private FilesViewModel viewModel;
    private PagesAdapter adapter;
    private final ActivityResultLauncher<String[]> filePicker =
            registerForActivityResult(new ActivityResultContracts.OpenMultipleDocuments(),
                    this::processSelectedFiles);

    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentFilesBinding.inflate(inflater, container, false);
        viewModel = new ViewModelProvider(requireActivity()).get(FilesViewModel.class); // Shared ViewModel

        setupRecyclerView();
        setupButtons();
        observeViewModel();

        return binding.getRoot();
    }

    private void setupRecyclerView() {
        adapter = new PagesAdapter(new ArrayList<>(), position -> {
            viewModel.removePage(position);
        });
        binding.recyclerPages.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.recyclerPages.setAdapter(adapter);
        // Add drag handle for reordering later
    }

    private void setupButtons() {
        binding.btnUpload.setOnClickListener(v -> {
            // Accept images, PDF, DOC, and DOCX files
            String[] mimeTypes = {
                "image/*",
                "application/pdf",
                "application/msword",  // .doc
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document"  // .docx
            };
            filePicker.launch(mimeTypes);
        });
        binding.btnProcessOcr.setOnClickListener(v -> viewModel.processOcr());
        binding.btnNextPages.setOnClickListener(v -> Navigation.findNavController(binding.getRoot())
                .navigate(R.id.navigation_pages));
        binding.btnNextPages.setOnClickListener(v -> {
            Navigation.findNavController(v).navigate(R.id.navigation_pages);
        });
    }

    private void observeViewModel() {
        viewModel.getPages().observe(getViewLifecycleOwner(), pages -> {
            adapter.updatePages(pages);
            binding.textFiles.setText("Pages: " + pages.size());
        });
    }

    /**
     * Process selected files (images, PDFs, DOC/DOCX)
     * Extract pages from documents and add to ViewModel
     */
    private void processSelectedFiles(List<Uri> uris) {
        if (uris == null || uris.isEmpty()) {
            return;
        }

        Toast.makeText(requireContext(), "Processing " + uris.size() + " file(s)...", Toast.LENGTH_SHORT).show();

        // Process files in background thread
        new Thread(() -> {
            File outputDir = new File(requireContext().getExternalFilesDir(Environment.DIRECTORY_PICTURES), "ScanDoc");
            if (!outputDir.exists()) {
                outputDir.mkdirs();
            }

            int totalPagesExtracted = 0;
            int filesProcessed = 0;
            int filesFailed = 0;

            for (Uri uri : uris) {
                try {
                    Log.d(TAG, "Processing file: " + uri);
                    List<String> extractedPages = DocumentProcessor.processDocument(requireContext(), uri, outputDir);

                    if (extractedPages != null && !extractedPages.isEmpty()) {
                        // Add extracted pages to ViewModel
                        for (String pagePath : extractedPages) {
                            requireActivity().runOnUiThread(() -> {
                                viewModel.addPage(pagePath, "Ready");
                            });
                        }
                        totalPagesExtracted += extractedPages.size();
                        filesProcessed++;
                        Log.d(TAG, "Extracted " + extractedPages.size() + " pages from: " + uri);
                    } else {
                        filesFailed++;
                        Log.w(TAG, "No pages extracted from: " + uri);
                    }
                } catch (Exception e) {
                    filesFailed++;
                    Log.e(TAG, "Error processing file: " + uri, e);
                }
            }

            // Show result message
            final int finalPagesExtracted = totalPagesExtracted;
            final int finalFilesProcessed = filesProcessed;
            final int finalFilesFailed = filesFailed;

            requireActivity().runOnUiThread(() -> {
                String message;
                if (finalFilesFailed == 0) {
                    message = "✅ Success!\n" + finalPagesExtracted + " pages extracted from " + finalFilesProcessed + " file(s)";
                } else {
                    message = "⚠️ Processed: " + finalFilesProcessed + " file(s)\n" +
                              "Pages extracted: " + finalPagesExtracted + "\n" +
                              "Failed: " + finalFilesFailed + " file(s)";
                }
                Toast.makeText(requireContext(), message, Toast.LENGTH_LONG).show();
            });
        }).start();
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
