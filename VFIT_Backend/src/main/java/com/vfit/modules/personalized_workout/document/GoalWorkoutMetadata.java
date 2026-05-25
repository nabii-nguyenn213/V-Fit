package com.vfit.modules.personalized_workout.document;

import com.vfit.common.enums.GoalType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.io.Serializable;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "goal_workout_metadata")
public class GoalWorkoutMetadata implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id; // Matches GoalType enum name, e.g., "LOSE_WEIGHT" or "GAIN_MUSCLE"
    private GoalType goalType;
    private Rules rules;
    private NutritionRecovery nutritionRecovery;
    private Map<Integer, DaySchedule> schedule; // Key: 1 (Monday) to 7 (Sunday)

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Rules implements Serializable {
        private static final long serialVersionUID = 1L;
        private RuleDetail compound;
        private RuleDetail isolation;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RuleDetail implements Serializable {
        private static final long serialVersionUID = 1L;
        private String reps;
        private String rest;
        private String rir;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class NutritionRecovery implements Serializable {
        private static final long serialVersionUID = 1L;
        private String caloriesTarget;
        private String proteinTarget;
        private String weightTarget;
        private String sleepTarget;
        private String waterTarget;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DaySchedule implements Serializable {
        private static final long serialVersionUID = 1L;
        private String dayName;
        private String dayType;
        private boolean restDay;
        private List<ExerciseItemMetadata> exercises;
        private String cardioAfterWorkout;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExerciseItemMetadata implements Serializable {
        private static final long serialVersionUID = 1L;
        private String exerciseId;
        private int sets;
        private String reps;
        private String notes;
    }
}
