package com.vfit.modules.payment.dto;

import java.math.BigDecimal;
import java.time.Instant;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class CheckoutResponseDto {
    private String orderId;
    private String transactionId;
    private String planCode;
    private BigDecimal originalAmount;
    private BigDecimal discountAmount;
    private BigDecimal finalAmount;
    private String voucherCode;
    private String status;
    private Instant premiumUntil;
}
