package com.vfit.modules.payment.service;

import com.vfit.modules.payment.config.PaymentProperties;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class VietQrService {
    private final PaymentProperties properties;

    public String buildQrUrl(BigDecimal amount, String paymentCode) {
        String baseUrl = trimTrailingSlash(properties.getVietQrBaseUrl());
        String addInfo = URLEncoder.encode(paymentCode, StandardCharsets.UTF_8);
        String accountName = URLEncoder.encode(properties.getAccountName(), StandardCharsets.UTF_8);
        return "%s/%s-%s-compact2.png?amount=%s&addInfo=%s&accountName=%s"
                .formatted(
                        baseUrl,
                        properties.getBankCode(),
                        properties.getAccountNumber(),
                        amount.toPlainString(),
                        addInfo,
                        accountName);
    }

    private String trimTrailingSlash(String value) {
        if (value == null || value.isBlank()) {
            return "https://img.vietqr.io/image";
        }
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }
}
