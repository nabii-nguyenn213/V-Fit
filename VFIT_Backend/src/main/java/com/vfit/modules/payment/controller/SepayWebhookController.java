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
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Collections;
import java.util.stream.Collectors;

@Hidden
@Slf4j
@RestController
@RequestMapping("/api/payments/sepay")
@RequiredArgsConstructor
public class SepayWebhookController {
    private final SepayWebhookService sepayWebhookService;
    private final com.vfit.modules.payment.config.PaymentProperties properties;

    @PostMapping("/webhook")
    public ResponseEntity<Void> handleWebhook(
            @RequestBody String rawBody,
            @RequestHeader(value = "X-SePay-Signature", required = false) String signature,
            @RequestHeader(value = "X-SePay-Timestamp", required = false) String timestamp,
            HttpServletRequest request) {
        log.info("[SEPAY] Webhook received, bytes={}, hasSignature={}",
                rawBody == null ? 0 : rawBody.length(),
                signature != null && !signature.isBlank());

        String secret = properties.getSepayWebhookSecret();
        String computedSignature = "";
        if (secret != null && !secret.isBlank() && rawBody != null && timestamp != null && !timestamp.isBlank()) {
            try {
                javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
                mac.init(new javax.crypto.spec.SecretKeySpec(secret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256"));
                String payloadToSign = timestamp.trim() + "." + rawBody;
                byte[] hash = mac.doFinal(payloadToSign.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                computedSignature = java.util.HexFormat.of().formatHex(hash);
            } catch (Exception e) {
                computedSignature = "Error: " + e.getMessage();
            }
        }

        try {
            StringBuilder debugInfo = new StringBuilder();
            debugInfo.append("=== WEBHOOK REQUEST ===\n");
            debugInfo.append("Time: ").append(java.time.Instant.now()).append("\n");
            debugInfo.append("Signature Header: ").append(signature).append("\n");
            debugInfo.append("Timestamp Header: ").append(timestamp).append("\n");
            debugInfo.append("Backend Configured Secret: ").append(secret == null ? "NULL" : (secret.isEmpty() ? "EMPTY" : "Length=" + secret.length() + " (starts with: " + secret.substring(0, Math.min(4, secret.length())) + ")")).append("\n");
            debugInfo.append("Backend Computed Signature: ").append(computedSignature).append("\n");
            debugInfo.append("Headers:\n");
            Collections.list(request.getHeaderNames()).forEach(headerName -> {
                debugInfo.append("  ").append(headerName).append(": ")
                        .append(Collections.list(request.getHeaders(headerName)).stream().collect(Collectors.joining(", ")))
                        .append("\n");
            });
            debugInfo.append("Body:\n").append(rawBody).append("\n\n");
            Files.writeString(Paths.get("sepay-webhook-debug.log"), debugInfo.toString(),
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            log.error("Failed to write webhook debug log", e);
        }

        try {
            sepayWebhookService.handleWebhook(rawBody, signature, timestamp);
            try {
                Files.writeString(Paths.get("sepay-webhook-debug.log"), "Response: 200 OK\n\n",
                        StandardOpenOption.CREATE, StandardOpenOption.APPEND);
            } catch (IOException ignored) {}
            return ResponseEntity.ok().build();
        } catch (com.vfit.common.exception.AppException e) {
            try {
                String errorMsg = "Response: " + e.getErrorCode().getStatus().value() + " " + e.getErrorCode().name() + " - " + e.getMessage() + "\n\n";
                Files.writeString(Paths.get("sepay-webhook-debug.log"), errorMsg,
                        StandardOpenOption.CREATE, StandardOpenOption.APPEND);
            } catch (IOException ignored) {}
            throw e;
        } catch (Exception e) {
            try {
                String errorMsg = "Response: 500 Internal Server Error - " + e.getMessage() + "\n\n";
                Files.writeString(Paths.get("sepay-webhook-debug.log"), errorMsg,
                        StandardOpenOption.CREATE, StandardOpenOption.APPEND);
            } catch (IOException ignored) {}
            throw e;
        }
    }
}
