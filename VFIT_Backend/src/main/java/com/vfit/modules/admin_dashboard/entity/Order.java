package com.vfit.modules.admin_dashboard.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.Instant;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "orders")
@CompoundIndex(name = "idx_orders_status_created", def = "{'status': 1, 'created_at': -1}")
public class Order {
    @Id
    private String id;

    @Field("user_id")
    private String userId;

    @Field("order_type")
    private String orderType;

    private Double amount;

    private String status; // SUCCESS, PENDING, FAILED

    @Field("voucher_code")
    private String voucherCode;

    @CreatedDate
    @Field("created_at")
    private Instant createdAt;
}
