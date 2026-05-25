package com.vfit.modules.payment.dto;

import com.vfit.modules.payment.enums.PaymentStatus;
import java.time.Instant;

public record PaymentStatusResponse(
        String paymentId,
        PaymentStatus status,
        boolean premiumUnlocked,
        Instant premiumExpiredAt
) {
}
