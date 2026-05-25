package com.vfit.modules.payment.enums;

import java.math.BigDecimal;
import java.util.Optional;

public enum VoucherType {
    MONTHLY_30K_OFF(BigDecimal.valueOf(30_000), PremiumPlan.MONTHLY),
    HALF_MONTH_10K_OFF(BigDecimal.valueOf(10_000), null);

    private final BigDecimal discountAmount;
    private final PremiumPlan applicablePlan;

    VoucherType(BigDecimal discountAmount, PremiumPlan applicablePlan) {
        this.discountAmount = discountAmount;
        this.applicablePlan = applicablePlan;
    }

    public BigDecimal discountAmount() {
        return discountAmount;
    }

    public Optional<PremiumPlan> applicablePlan() {
        return Optional.ofNullable(applicablePlan);
    }
}
