package com.vfit.modules.payment.service;

public interface SepayWebhookService {
    void handleWebhook(String rawBody, String signature, String timestamp);
}
