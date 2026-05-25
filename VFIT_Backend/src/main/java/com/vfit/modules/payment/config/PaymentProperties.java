package com.vfit.modules.payment.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Getter
@Component
public class PaymentProperties {
    @Value("${sepay.webhook-secret:}")
    private String sepayWebhookSecret;

    @Value("${sepay.bank-code:}")
    private String bankCode;

    @Value("${sepay.account-number:}")
    private String accountNumber;

    @Value("${sepay.account-name:}")
    private String accountName;

    @Value("${vietqr.base-url:https://img.vietqr.io/image}")
    private String vietQrBaseUrl;

    @Value("${payment.expiry-minutes:15}")
    private long expiryMinutes;
}
