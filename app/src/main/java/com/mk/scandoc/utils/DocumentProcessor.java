package com.mk.scandoc.utils;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.pdf.PdfRenderer;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Helper class to process PDF and DOC/DOCX files
 * Extracts pages as images for OCR processing
 */
public class DocumentProcessor {
    private static final String TAG = "DocumentProcessor";

    /**
     * Process a document file (PDF or DOC/DOCX) and extract pages as images
     * 
     * @param context Application context
     * @param uri URI of the document file
     * @param outputDir Directory to save extracted page images
     * @return List of file paths to extracted page images
     */
    public static List<String> processDocument(Context context, Uri uri, File outputDir) {
        List<String> extractedPages = new ArrayList<>();
        
        String mimeType = context.getContentResolver().getType(uri);
        Log.d(TAG, "Processing document: " + uri + ", MIME type: " + mimeType);
        
        if (mimeType == null) {
            // Try to determine from file extension
            String uriString = uri.toString().toLowerCase();
            if (uriString.endsWith(".pdf")) {
                mimeType = "application/pdf";
            } else if (uriString.endsWith(".doc")) {
                mimeType = "application/msword";
            } else if (uriString.endsWith(".docx")) {
                mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            }
        }
        
        try {
            if ("application/pdf".equals(mimeType)) {
                extractedPages = processPdf(context, uri, outputDir);
            } else if ("application/msword".equals(mimeType) || 
                       "application/vnd.openxmlformats-officedocument.wordprocessingml.document".equals(mimeType)) {
                extractedPages = processWordDocument(context, uri, outputDir);
            } else if (mimeType != null && mimeType.startsWith("image/")) {
                // It's an image, just copy it
                extractedPages = processImage(context, uri, outputDir);
            } else {
                Log.e(TAG, "Unsupported file type: " + mimeType);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error processing document: " + e.getMessage(), e);
        }
        
        return extractedPages;
    }

    /**
     * Extract pages from PDF as images
     */
    private static List<String> processPdf(Context context, Uri uri, File outputDir) throws IOException {
        List<String> extractedPages = new ArrayList<>();
        
        // Copy PDF to temp file (PdfRenderer requires a file descriptor)
        File tempPdf = new File(context.getCacheDir(), "temp_" + System.currentTimeMillis() + ".pdf");
        copyUriToFile(context, uri, tempPdf);
        
        ParcelFileDescriptor fileDescriptor = ParcelFileDescriptor.open(tempPdf, ParcelFileDescriptor.MODE_READ_ONLY);
        PdfRenderer pdfRenderer = new PdfRenderer(fileDescriptor);
        
        int pageCount = pdfRenderer.getPageCount();
        Log.d(TAG, "PDF has " + pageCount + " pages");
        
        for (int i = 0; i < pageCount; i++) {
            PdfRenderer.Page page = pdfRenderer.openPage(i);
            
            // Create bitmap with high resolution for better OCR
            int width = page.getWidth() * 2;  // 2x resolution
            int height = page.getHeight() * 2;
            Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            
            // Render PDF page to bitmap
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);
            page.close();
            
            // Save bitmap as JPEG
            String filename = "pdf_page_" + System.currentTimeMillis() + "_" + (i + 1) + ".jpg";
            File outputFile = new File(outputDir, filename);
            
            FileOutputStream fos = new FileOutputStream(outputFile);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
            fos.flush();
            fos.close();
            bitmap.recycle();
            
            extractedPages.add(outputFile.getAbsolutePath());
            Log.d(TAG, "Extracted PDF page " + (i + 1) + " to: " + outputFile.getAbsolutePath());
        }
        
        pdfRenderer.close();
        fileDescriptor.close();
        tempPdf.delete();  // Clean up temp file
        
        return extractedPages;
    }

    /**
     * Process Word document (DOC/DOCX)
     * Note: Word documents don't have a concept of "pages" like PDFs
     * We'll create a single image representation for now
     */
    private static List<String> processWordDocument(Context context, Uri uri, File outputDir) throws IOException {
        List<String> extractedPages = new ArrayList<>();
        
        // For now, we'll show a message that DOC/DOCX needs to be converted to PDF first
        // Full DOC/DOCX rendering would require complex libraries
        Log.w(TAG, "DOC/DOCX processing not fully implemented yet. Please convert to PDF first.");
        
        // TODO: Implement DOC/DOCX rendering or show user message to convert to PDF
        
        return extractedPages;
    }

    /**
     * Process image file (copy to output directory)
     */
    private static List<String> processImage(Context context, Uri uri, File outputDir) throws IOException {
        List<String> extractedPages = new ArrayList<>();
        
        String filename = "image_" + System.currentTimeMillis() + ".jpg";
        File outputFile = new File(outputDir, filename);
        
        copyUriToFile(context, uri, outputFile);
        extractedPages.add(outputFile.getAbsolutePath());
        
        Log.d(TAG, "Copied image to: " + outputFile.getAbsolutePath());
        return extractedPages;
    }

    /**
     * Copy content from URI to file
     */
    private static void copyUriToFile(Context context, Uri uri, File destFile) throws IOException {
        InputStream inputStream = context.getContentResolver().openInputStream(uri);
        if (inputStream == null) {
            throw new IOException("Failed to open input stream for URI: " + uri);
        }
        
        FileOutputStream outputStream = new FileOutputStream(destFile);
        byte[] buffer = new byte[8192];
        int bytesRead;
        
        while ((bytesRead = inputStream.read(buffer)) != -1) {
            outputStream.write(buffer, 0, bytesRead);
        }
        
        outputStream.flush();
        outputStream.close();
        inputStream.close();
    }
}

