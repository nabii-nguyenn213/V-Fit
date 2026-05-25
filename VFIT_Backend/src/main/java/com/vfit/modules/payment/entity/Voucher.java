package com.vfit.modules.payment.entity;

import com.vfit.modules.payment.enums.PremiumPlan;
import com.vfit.modules.payment.enums.VoucherStatus;
import com.vfit.modules.payment.enums.VoucherType;
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
import org.springframework.data.mongodb.core.mapping.Field;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "vouchers")
public class Voucher {
    @Id
    private String id;
    @Indexed(unique = true)
    private String code;
    private VoucherType type;
    private BigDecimal discountAmount;
    private PremiumPlan applicablePlan;
    @Indexed
    private String userId;
    @Field("is_public")
    private boolean isPublic;
    @Indexed
    private VoucherStatus status;
    @CreatedDate
    private Instant createdAt;
    @Indexed
    private Instant expiredAt;
    private Instant usedAt;
    private String usedByPaymentId;
    @LastModifiedDate
    private Instant updatedAt;
}
