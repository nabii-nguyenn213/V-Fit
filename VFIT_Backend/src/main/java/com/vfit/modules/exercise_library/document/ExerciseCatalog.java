package com.vfit.modules.exercise_library.document;

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
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "exercise_catalogs")
@CompoundIndexes({
        @CompoundIndex(name = "idx_version_active", def = "{ 'version': -1, 'active': 1 }")
})
public class ExerciseCatalog {
    @Id
    private String id;
    private int version;
    @Indexed
    private String locale;
    @Indexed
    private boolean active;
    @Builder.Default
    private List<MuscleGroup> groups = new ArrayList<>();
    @CreatedDate
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MuscleGroup {
        private String slug;
        private String name;
        private int sortOrder;
        @Builder.Default
        private List<SubMuscleGroup> subGroups = new ArrayList<>();
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubMuscleGroup {
        private String slug;
        private String name;
        private int sortOrder;
        @Builder.Default
        private List<ExerciseItem> exercises = new ArrayList<>();
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExerciseItem {
        private String id;
        private String name;
        private String videoUrl;
        private String videoSearchHint;
        private String description;
        @Builder.Default
        private List<String> equipment = new ArrayList<>();
        private int sortOrder;
        @Builder.Default
        private boolean active = true;
    }
}
