package com.mk.scandoc.ui.files;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;
import android.net.Uri;
import java.util.ArrayList;
import java.util.List;

public class FilesViewModel extends ViewModel {
    private final MutableLiveData<List<PageData>> pages = new MutableLiveData<>(new ArrayList<>());

    public LiveData<List<PageData>> getPages() { return pages; }

    public void addPages(List<Uri> uris) {
        List<PageData> current = new ArrayList<>(pages.getValue());
        for (Uri uri : uris) {
            current.add(new PageData(uri.toString(), "Uploaded"));
        }
        pages.setValue(current);
    }

    public void addPage(String uri, String status) {
        List<PageData> current = new ArrayList<>(pages.getValue());
        current.add(new PageData(uri, status));
        pages.setValue(current);
    }

    public void removePage(int position) {
        List<PageData> current = new ArrayList<>(pages.getValue());
        if (position >= 0 && position < current.size()) {
            current.remove(position);
        }
        pages.setValue(current);
    }

    public void processOcr() { }
}