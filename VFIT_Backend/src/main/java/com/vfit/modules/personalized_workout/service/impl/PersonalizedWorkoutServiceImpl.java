package com.vfit.modules.personalized_workout.service.impl;

import com.vfit.common.enums.GoalType;
import com.vfit.modules.personalized_workout.document.GoalWorkoutMetadata;
import com.vfit.modules.personalized_workout.dto.PersonalizedWorkoutResponse;
import com.vfit.modules.personalized_workout.repository.GoalWorkoutMetadataRepository;
import com.vfit.modules.personalized_workout.service.PersonalizedWorkoutService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class PersonalizedWorkoutServiceImpl implements PersonalizedWorkoutService {

    private final UserRepository userRepository;
    private final GoalWorkoutMetadataRepository goalWorkoutMetadataRepository;

    @Override
    @Cacheable(value = "personalized_workouts", key = "#userId", unless = "#result == null || !#result.hasGoal")
    public PersonalizedWorkoutResponse getPersonalizedWorkoutPlan(String userId) {
        log.info("Fetching personalized workout plan from Database for userId: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> {
                    log.error("User with ID: {} not found", userId);
                    return new IllegalArgumentException("User not found");
                });

        GoalType goalType = user.getGoalType();
        if (goalType == null) {
            log.info("User {} does not have a fitness goal set", userId);
            return PersonalizedWorkoutResponse.empty();
        }

        log.info("Retrieving workout metadata for goal type: {}", goalType);
        GoalWorkoutMetadata metadata = goalWorkoutMetadataRepository.findByGoalType(goalType)
                .orElseThrow(() -> {
                    log.error("Goal workout metadata not found for goal: {}", goalType);
                    return new IllegalStateException("Metadata for goal " + goalType + " is not initialized in database");
                });

        return PersonalizedWorkoutResponse.builder()
                .hasGoal(true)
                .goalType(goalType)
                .rules(metadata.getRules())
                .nutritionRecovery(metadata.getNutritionRecovery())
                .schedule(metadata.getSchedule())
                .build();
    }
}
