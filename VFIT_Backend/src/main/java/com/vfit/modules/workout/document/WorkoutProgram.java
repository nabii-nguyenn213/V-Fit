package com.vfit.modules.workout.document;

import com.vfit.common.enums.DifficultyLevel;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "workout_programs")
public class WorkoutProgram {
    @Id
    private String id;
    private String title;
    private String description;
    private DifficultyLevel difficulty;
    private int durationMinutes;
    @Builder.Default
    private List<String> exerciseIds = new ArrayList<>();
    @CreatedDate
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;
}
