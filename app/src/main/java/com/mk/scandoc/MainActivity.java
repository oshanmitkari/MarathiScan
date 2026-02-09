package com.mk.scandoc;

import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import com.google.android.material.bottomnavigation.BottomNavigationView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.navigation.NavController;
import androidx.navigation.Navigation;
import androidx.navigation.ui.AppBarConfiguration;
import androidx.navigation.ui.NavigationUI;

import com.mk.scandoc.databinding.ActivityMainBinding;
import com.mk.scandoc.utils.TesseractHelper;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private ActivityMainBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        try {
            Log.d(TAG, "MainActivity onCreate started");

            binding = ActivityMainBinding.inflate(getLayoutInflater());
            setContentView(binding.getRoot());

            // Copy Tesseract traineddata files (MUST run before OCR)
            try {
                Log.d(TAG, "=== Tesseract Traineddata Setup ===");
                boolean success = TesseractHelper.copyTrainedDataIfNeeded(this);

                if (success) {
                    Log.d(TAG, "[SUCCESS] Tesseract files ready");
                } else {
                    Log.e(TAG, "[ERROR] Failed to copy Tesseract files");
                    Toast.makeText(this, "ERROR: Failed to initialize OCR", Toast.LENGTH_LONG).show();
                }
            } catch (Exception e) {
                Log.e(TAG, "[ERROR] Exception: " + e.getMessage(), e);
                Toast.makeText(this, "Error initializing OCR: " + e.getMessage(), Toast.LENGTH_LONG).show();
            }

            // Setup navigation
            try {
                Log.d(TAG, "Setting up navigation...");
                BottomNavigationView navView = findViewById(R.id.nav_view);
                AppBarConfiguration appBarConfiguration = new AppBarConfiguration.Builder(
                        R.id.navigation_pages, R.id.navigation_scan, R.id.navigation_files)
                        .build();
                NavController navController = Navigation.findNavController(this, R.id.nav_host_fragment_activity_main);
                NavigationUI.setupActionBarWithNavController(this, navController, appBarConfiguration);
                NavigationUI.setupWithNavController(binding.navView, navController);
                Log.d(TAG, "[OK] Navigation setup complete");
            } catch (Exception e) {
                Log.e(TAG, "[ERROR] Navigation setup failed: " + e.getMessage(), e);
                Toast.makeText(this, "Error setting up navigation: " + e.getMessage(), Toast.LENGTH_LONG).show();
            }

            Log.d(TAG, "[OK] MainActivity onCreate completed successfully");

        } catch (Exception e) {
            Log.e(TAG, "[FATAL] MainActivity onCreate failed: " + e.getMessage(), e);
            Toast.makeText(this, "Fatal error starting app: " + e.getMessage(), Toast.LENGTH_LONG).show();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == 101) { // STORAGE_PERMISSION_CODE
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "[OK] Permission granted", Toast.LENGTH_SHORT).show();
                Log.d(TAG, "[OK] Storage permission granted");
            } else {
                Toast.makeText(this, "[ERROR] Permission denied", Toast.LENGTH_SHORT).show();
                Log.w(TAG, "[WARNING] Storage permission denied");
            }
        }
    }


}