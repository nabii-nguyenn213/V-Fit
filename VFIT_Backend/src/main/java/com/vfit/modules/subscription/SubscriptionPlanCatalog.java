package com.vfit.modules.subscription;

import java.math.BigDecimal;
import java.util.List;

public final class SubscriptionPlanCatalog {
    public static final String CURRENCY = "VND";
    public static final Plan VIP_MONTHLY = new Plan("VIP_MONTHLY", "VIP monthly", BigDecimal.valueOf(150_000), 30);
    public static final Plan VIP_YEARLY = new Plan("VIP_YEARLY", "VIP yearly", BigDecimal.valueOf(1_000_000), 365);

    private SubscriptionPlanCatalog() {
    }

    public static List<Plan> vipPlans() {
        return List.of(VIP_MONTHLY, VIP_YEARLY);
    }

    public record Plan(String code, String name, BigDecimal price, int durationDays) {
    }
}
