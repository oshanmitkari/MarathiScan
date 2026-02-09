package com.mk.scandoc.ui.pages;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

public class PagesViewModel extends ViewModel {

    private final MutableLiveData<String> mText;

    public PagesViewModel() {
        mText = new MutableLiveData<>();
        mText.setValue("You can arrange pages here.");
    }

    public LiveData<String> getText() {
        return mText;
    }
}