package com.vfit.modules.exercise.document;

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
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "exercises")
public class Exercise {
    @Id
    private String id;
    @Indexed
    private String name;
    @Indexed
    private String muscleGroup;
    @Indexed
    private DifficultyLevel difficulty;
    @Builder.Default
    private List<String> instructions = new ArrayList<>();
    private String videoUrl;
    private String thumbnailUrl;
    @CreatedDate
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;
}
