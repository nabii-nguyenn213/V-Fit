package com.vfit.modules.payment.websocket;

import com.vfit.modules.payment.enums.PaymentStatus;
import java.time.Instant;

public record PaymentWebSocketEvent(
        String type,
        String paymentId,
        PaymentStatus status,
        boolean premiumUnlocked,
        Instant paidAt) {
    public static PaymentWebSocketEvent paid(String paymentId, Instant paidAt) {
        return new PaymentWebSocketEvent("PAYMENT_PAID", paymentId, PaymentStatus.PAID, true, paidAt);
    }
}
