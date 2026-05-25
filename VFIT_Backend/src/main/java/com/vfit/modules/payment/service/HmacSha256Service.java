package com.vfit.modules.payment.service;

import com.vfit.modules.payment.config.PaymentProperties;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class HmacSha256Service {
    private static final String HMAC_SHA256 = "HmacSHA256";
    private final PaymentProperties properties;

    public boolean verify(String rawBody, String signature, String timestamp) {
        if (rawBody == null || signature == null || signature.isBlank() || timestamp == null || timestamp.isBlank()) {
            log.warn("[SEPAY] Webhook verification failed: rawBody, signature or timestamp is missing");
            return false;
        }
        String secret = properties.getSepayWebhookSecret();
        if (secret == null || secret.isBlank()) {
            log.error("[SEPAY] Webhook verification failed: sepay.webhook-secret (SEPAY_WEBHOOK_SECRET) is NOT configured or is empty!");
            return false;
        }

        try {
            long tsSeconds = Long.parseLong(timestamp.trim());
            long currentSeconds = java.time.Instant.now().getEpochSecond();
            if (Math.abs(currentSeconds - tsSeconds) > 300) {
                log.warn("[SEPAY] Webhook timestamp is skewed by {} seconds. Local machine time might be desynced.", currentSeconds - tsSeconds);
            }
        } catch (NumberFormatException e) {
            log.warn("[SEPAY] Webhook timestamp format is invalid: {}", timestamp);
        }

        try {
            Mac mac = Mac.getInstance(HMAC_SHA256);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_SHA256));
            
            String payloadToSign = timestamp.trim() + "." + rawBody;
            byte[] expectedBytes = mac.doFinal(payloadToSign.getBytes(StandardCharsets.UTF_8));
            String expectedHex = HexFormat.of().formatHex(expectedBytes);
            String receivedHex = normalizeSignature(signature);
            boolean verified = MessageDigest.isEqual(
                    expectedHex.getBytes(StandardCharsets.UTF_8),
                    receivedHex.getBytes(StandardCharsets.UTF_8));
            if (!verified) {
                log.warn("[SEPAY] Signature mismatch! Expected: {}, Received (normalized): {}", expectedHex, receivedHex);
            }
            return verified;
        } catch (Exception ex) {
            log.error("[SEPAY] Error calculating signature hash", ex);
            return false;
        }
    }

    private String normalizeSignature(String signature) {
        String value = signature.trim().toLowerCase();
        if (value.startsWith("sha256=")) {
            return value.substring("sha256=".length());
        }
        return value;
    }
}
