package com.vfit.modules.user.dto.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class OnboardingProfileRequest {
    @DecimalMin("80.0")
    @DecimalMax("250.0")
    private Double heightCm;

    @DecimalMin("20.0")
    @DecimalMax("300.0")
    private Double weightKg;

    @DecimalMin("1.0")
    @DecimalMax("70.0")
    private Double bodyFatPercent;
}
