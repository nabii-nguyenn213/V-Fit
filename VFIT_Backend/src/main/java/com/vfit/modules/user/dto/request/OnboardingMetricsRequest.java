package com.vfit.modules.user.dto.request;

import com.vfit.common.enums.GoalType;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class OnboardingMetricsRequest {
    @NotNull(message = "Goal type is required")
    private GoalType goalType;

    @DecimalMin(value = "80.0", message = "Height must be at least 80cm")
    @DecimalMax(value = "250.0", message = "Height must be at most 250cm")
    private Double heightCm;

    @DecimalMin(value = "20.0", message = "Weight must be at least 20kg")
    @DecimalMax(value = "300.0", message = "Weight must be at most 300kg")
    private Double weightKg;

    @DecimalMin(value = "1.0", message = "Body fat percent must be at least 1%")
    @DecimalMax(value = "70.0", message = "Body fat percent must be at most 70%")
    private Double bodyFatPercent;
}
