package com.vfit.modules.workout.document;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "workout_histories")
public class WorkoutHistory {
    @Id
    private String id;
    @Indexed
    private String userId;
    private String workoutProgramId;
    private Instant startedAt;
    private Instant completedAt;
    private int xpEarned;
    @CreatedDate
    private Instant createdAt;
}
