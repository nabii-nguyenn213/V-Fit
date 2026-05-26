package com.vfit.modules.payment.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;

public record VipStatusResponse(
        @JsonProperty("isVip")
        boolean isVip,
        String vipType,
        Instant expiredAt,
        long remainingDays,
        boolean canRenew
) {
}
