package com.vfit.modules.subscription.document;

import com.vfit.modules.payment.enums.PaymentStatus;
import com.vfit.modules.payment.enums.PremiumPlan;
import java.math.BigDecimal;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "payment_transactions")
public class PaymentTransaction {
    @Id
    private String id;
    @Indexed
    private String userId;
    private PremiumPlan plan;
    private BigDecimal baseAmount;
    private BigDecimal discountAmount;
    private BigDecimal finalAmount;
    // Legacy amount field retained for older checkout records; premium QR uses finalAmount.
    private BigDecimal amount;
    private String currency;
    @Indexed(unique = true, sparse = true)
    private String paymentCode;
    private String voucherCode;
    @Indexed
    private PaymentStatus paymentStatus;
    private String vietQrUrl;
    @Indexed(unique = true, sparse = true)
    private String sepayTransactionId;
    private String sepayRawPayload;
    private Instant paidAt;
    @Indexed
    private Instant expiredAt;

    // Legacy checkout fields kept for backward compatibility with voucher flow.
    private String providerRef;
    @Indexed
    private String status;
    @CreatedDate
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;
}
