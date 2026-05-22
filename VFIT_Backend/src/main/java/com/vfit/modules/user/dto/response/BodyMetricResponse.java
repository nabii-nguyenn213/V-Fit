package com.vfit.modules.user.dto.response;

import java.time.Instant;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class BodyMetricResponse {
    private final Double heightCm;
    private final Double weightKg;
    private final Double bodyFatPercent;
    private final Double bmi;
    private final Instant measuredAt;
}
