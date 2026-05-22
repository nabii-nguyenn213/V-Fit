package com.vfit.modules.checkin.entity;

import java.math.BigDecimal;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "user_vouchers")
@CompoundIndex(
        name = "ux_voucher_user_month_milestone",
        def = "{'user_id': 1, 'month_key': 1, 'reward_milestone': 1}",
        unique = true)
public class UserVoucher {
    @Id
    private String id;

    @Indexed
    @Field("user_id")
    private String userId;

    @Indexed(unique = true)
    private String code;

    private BigDecimal amount;

    private UserVoucherStatus status;

    @Field("issued_at")
    private Instant issuedAt;

    @Indexed
    @Field("expired_at")
    private Instant expiredAt;

    @Field("used_at")
    private Instant usedAt;

    @Field("used_order_id")
    private String usedOrderId;

    @Field("month_key")
    private String monthKey;

    @Field("reward_milestone")
    private Integer rewardMilestone;
}
