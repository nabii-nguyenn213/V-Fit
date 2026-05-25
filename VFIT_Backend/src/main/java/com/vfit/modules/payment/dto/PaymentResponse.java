package com.vfit.modules.payment.dto;

import com.vfit.modules.payment.enums.PremiumPlan;
import java.math.BigDecimal;
import java.time.Instant;

public record PaymentResponse(
        String paymentId,
        PremiumPlan plan,
        BigDecimal baseAmount,
        BigDecimal discountAmount,
        BigDecimal finalAmount,
        String bankCode,
        String accountNumber,
        String accountName,
        String paymentCode,
        String voucherCode,
        String vietQrUrl,
        Instant expiredAt
) {
}
