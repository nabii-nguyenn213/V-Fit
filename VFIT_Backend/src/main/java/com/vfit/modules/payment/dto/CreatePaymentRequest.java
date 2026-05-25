package com.vfit.modules.payment.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.vfit.modules.payment.enums.PremiumPlan;
import jakarta.validation.constraints.NotNull;

public record CreatePaymentRequest(
        @NotNull @JsonAlias("packageType") PremiumPlan plan,
        String voucherCode
) {
}
