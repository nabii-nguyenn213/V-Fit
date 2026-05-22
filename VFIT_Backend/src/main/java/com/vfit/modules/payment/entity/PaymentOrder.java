package com.vfit.modules.payment.entity;

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
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "payment_orders")
@CompoundIndex(name = "idx_payment_order_user_status_created", def = "{'user_id': 1, 'status': 1, 'created_at': -1}")
public class PaymentOrder {
    @Id
    private String id;

    @Field("user_id")
    private String userId;

    @Field("plan_code")
    private String planCode;

    @Field("original_amount")
    private BigDecimal originalAmount;

    @Field("discount_amount")
    private BigDecimal discountAmount;

    @Field("final_amount")
    private BigDecimal finalAmount;

    @Field("voucher_code")
    private String voucherCode;

    private PaymentOrderStatus status;

    @CreatedDate
    @Field("created_at")
    private Instant createdAt;

    @LastModifiedDate
    @Field("updated_at")
    private Instant updatedAt;
}
