package com.vfit.modules.ai.dto.response;

import java.time.Instant;
import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class FoodCalorieEstimateResponse {
    private final String foodName;
    private final String servingSize;
    private final int calories;
    private final double proteinGrams;
    private final double carbGrams;
    private final double fatGrams;
    private final double confidence;
    private final List<String> notes;
    private final Instant estimatedAt;
}
