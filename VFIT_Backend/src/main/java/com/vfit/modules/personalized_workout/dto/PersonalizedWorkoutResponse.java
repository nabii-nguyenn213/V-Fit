package com.vfit.modules.personalized_workout.dto;

import com.vfit.common.enums.GoalType;
import com.vfit.modules.personalized_workout.document.GoalWorkoutMetadata;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PersonalizedWorkoutResponse implements Serializable {
    private static final long serialVersionUID = 1L;

    private boolean hasGoal;
    private GoalType goalType;
    private GoalWorkoutMetadata.Rules rules;
    private GoalWorkoutMetadata.NutritionRecovery nutritionRecovery;
    private Map<Integer, GoalWorkoutMetadata.DaySchedule> schedule;
    private String message;

    public static PersonalizedWorkoutResponse empty() {
        return PersonalizedWorkoutResponse.builder()
                .hasGoal(false)
                .message("User has skipped onboarding goals.")
                .build();
    }
}
