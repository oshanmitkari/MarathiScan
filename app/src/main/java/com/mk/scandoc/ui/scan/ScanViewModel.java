package com.mk.scandoc.ui.scan;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class ScanViewModel extends ViewModel {
    private final MutableLiveData<String> mText = new MutableLiveData<>();

    public ScanViewModel() {
        mText.setValue("📷 Tap 'Scan Document' to capture enhanced pages");
    }

    // ✅ MISSING METHOD - ADD THIS
    public LiveData<String> getText() {
        return mText;
    }
}
