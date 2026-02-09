package com.mk.scandoc.ui.files;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.mk.scandoc.R;
import java.util.List;
import com.mk.scandoc.ui.files.PageData;
public class PagesAdapter extends RecyclerView.Adapter<PagesAdapter.ViewHolder> {
    private List<PageData> pages;
    private OnPageRemoveListener listener;

    public PagesAdapter(List<PageData> pages, OnPageRemoveListener listener) {
        this.pages = pages;
        this.listener = listener;
    }

    public void updatePages(List<PageData> newPages) {
        this.pages = newPages;
        notifyDataSetChanged();
    }

    @NonNull @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_page, parent, false);
        return new ViewHolder(view);
    }

    @Override public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        PageData page = pages.get(position);
        holder.textStatus.setText(page.status);
        Glide.with(holder.itemView).load(page.uri).into(holder.imagePreview);
        holder.btnRemove.setOnClickListener(v -> listener.onRemove(position));
    }

    @Override public int getItemCount() { return pages.size(); }

    class ViewHolder extends RecyclerView.ViewHolder {
        ImageView imagePreview;
        TextView textStatus;
        ImageView btnRemove;
        ViewHolder(@NonNull View itemView) {
            super(itemView);
            imagePreview = itemView.findViewById(R.id.imagePreview);
            textStatus = itemView.findViewById(R.id.textStatus);
            btnRemove = itemView.findViewById(R.id.btnRemove);
        }
    }

    interface OnPageRemoveListener {
        void onRemove(int position);
    }
}
