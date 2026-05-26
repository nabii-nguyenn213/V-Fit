package com.vfit.modules.payment.controller;

import com.vfit.modules.payment.service.SepayWebhookService;
import io.swagger.v3.oas.annotations.Hidden;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Hidden
@Slf4j
@RestController
@RequestMapping("/api/payments/sepay")
@RequiredArgsConstructor
public class SepayWebhookController {
    private final SepayWebhookService sepayWebhookService;

    @PostMapping("/webhook")
    public ResponseEntity<Void> handleWebhook(
            @RequestBody String rawBody,
            @RequestHeader(value = "X-SePay-Signature", required = false) String signature,
            @RequestHeader(value = "X-SePay-Timestamp", required = false) String timestamp) {
        log.info("[SEPAY] Webhook received, bytes={}, hasSignature={}",
                rawBody == null ? 0 : rawBody.length(),
                signature != null && !signature.isBlank());

        sepayWebhookService.handleWebhook(rawBody, signature, timestamp);
        return ResponseEntity.ok().build();
    }
}

