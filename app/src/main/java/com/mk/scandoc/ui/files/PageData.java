package com.mk.scandoc.ui.files;

public class PageData {
    public String uri;
    public String status;

    // Constructor with both parameters
    public PageData(String uri, String status) {
        this.uri = uri;
        this.status = status;
    }

    // Add convenience constructor for backward compatibility
    public PageData(String uri) {
        this.uri = uri;
        this.status = "Ready";
    }
}