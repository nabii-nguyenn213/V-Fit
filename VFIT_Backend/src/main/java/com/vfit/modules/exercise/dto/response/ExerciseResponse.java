package com.vfit.modules.exercise.dto.response;

import com.vfit.common.enums.DifficultyLevel;
import java.time.Instant;
import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ExerciseResponse {
    private final String id;
    private final String name;
    private final String muscleGroup;
    private final DifficultyLevel difficulty;
    private final List<String> instructions;
    private final String videoUrl;
    private final String thumbnailUrl;
    private final Instant createdAt;
}
