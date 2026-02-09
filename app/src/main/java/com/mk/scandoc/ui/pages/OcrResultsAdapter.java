package com.mk.scandoc.ui.pages;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.mk.scandoc.R;
import com.mk.scandoc.ui.files.PageData;
import java.util.ArrayList;
import java.util.List;
import com.mk.scandoc.ui.pages.OcrPageData;

public class OcrResultsAdapter extends RecyclerView.Adapter<OcrResultsAdapter.ViewHolder> {
    private List<OcrPageData> ocrData = new ArrayList<>();

    public void updateOcrData(OcrPageData[] data) {
        this.ocrData.clear();
        if (data != null) {
            for (OcrPageData item : data) {
                this.ocrData.add(item);
            }
        }
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_ocr_result, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        OcrPageData item = ocrData.get(position);
        holder.textPageNumber.setText("Page " + (position + 1));
        holder.textOcrResult.setText(item.ocrText != null ? item.ocrText : "Processing...");
        holder.textStatus.setText(item.status);
    }

    @Override
    public int getItemCount() {
        return ocrData.size();
    }

    public List<OcrPageData> getOcrData() {
        return new ArrayList<>(ocrData);
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView textPageNumber, textOcrResult, textStatus;

        ViewHolder(@NonNull View itemView) {
            super(itemView);
            textPageNumber = itemView.findViewById(R.id.textPageNumber);
            textOcrResult = itemView.findViewById(R.id.textOcrResult);
            textStatus = itemView.findViewById(R.id.textStatus);
        }
    }
}

