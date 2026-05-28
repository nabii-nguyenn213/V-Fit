package com.vfit.modules.ai.mapper;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.infrastructure.external.ai.dto.AiFoodCalorieEstimate;
import com.vfit.modules.ai.dto.response.FoodCalorieEstimateResponse;
import com.vfit.modules.user.dto.response.OnboardingResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.ERROR, imports = Instant.class)
public interface AiResultMapper {
    TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    @Mapping(target = "notes", expression = "java(toNotes(result.notes()))")
    @Mapping(target = "estimatedAt", expression = "java(Instant.now())")
    FoodCalorieEstimateResponse toFoodCalorieEstimateResponse(AiFoodCalorieEstimate result);

    @Mapping(target = "onboardingStatus", source = "onboardingStatus")
    @Mapping(target = "user", source = "user")
    @Mapping(target = "posture", source = "analysis.posture")
    @Mapping(target = "imbalance", source = "analysis.imbalance")
    @Mapping(target = "estimate", source = "analysis.estimate")
    @Mapping(target = "recommendation", source = "analysis.recommendation")
    @Mapping(target = "fallback", expression = "java(analysis.fallback())")
    OnboardingResponse toOnboardingResponse(
            OnboardingStatus onboardingStatus,
            UserResponse user,
            AiBodyAnalysisResult analysis);

    default List<String> toNotes(String note) {
        if (note == null || note.isBlank()) {
            return List.of("Realtime estimate only.");
        }
        return List.of(note);
    }

    default Map<String, Object> toMap(ObjectMapper objectMapper, Object value) {
        if (value == null) {
            return Map.of();
        }
        return objectMapper.convertValue(value, MAP_TYPE);
    }
}
