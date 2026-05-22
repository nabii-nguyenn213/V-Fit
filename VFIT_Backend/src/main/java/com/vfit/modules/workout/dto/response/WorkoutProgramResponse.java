package com.vfit.modules.workout.dto.response;

import com.vfit.common.enums.DifficultyLevel;
import java.time.Instant;
import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WorkoutProgramResponse {
    private final String id;
    private final String title;
    private final String description;
    private final DifficultyLevel difficulty;
    private final int durationMinutes;
    private final List<String> exerciseIds;
    private final Instant createdAt;
}
