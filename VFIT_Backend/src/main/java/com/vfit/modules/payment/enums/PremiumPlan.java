package com.vfit.modules.payment.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.math.BigDecimal;
import java.time.Duration;
import java.util.Locale;

public enum PremiumPlan {
    MONTHLY("VIP_MONTHLY", BigDecimal.valueOf(150_000), Duration.ofDays(30)),
    YEARLY("VIP_YEARLY", BigDecimal.valueOf(1_000_000), Duration.ofDays(365));

    private final String planCode;
    private final BigDecimal basePrice;
    private final Duration duration;

    PremiumPlan(String planCode, BigDecimal basePrice, Duration duration) {
        this.planCode = planCode;
        this.basePrice = basePrice;
        this.duration = duration;
    }

    public String planCode() {
        return planCode;
    }

    public BigDecimal basePrice() {
        return basePrice;
    }

    public Duration duration() {
        return duration;
    }

    @JsonValue
    public String jsonValue() {
        return name();
    }

    @JsonCreator
    public static PremiumPlan fromJson(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return switch (value.trim().toUpperCase(Locale.ROOT)) {
            case "MONTHLY", "MONTHLY_150K", "VIP_MONTHLY" -> MONTHLY;
            case "YEARLY", "YEARLY_1M", "PLAN_1M", "VIP_YEARLY" -> YEARLY;
            default -> throw new IllegalArgumentException("Unsupported premium plan: " + value);
        };
    }
}
