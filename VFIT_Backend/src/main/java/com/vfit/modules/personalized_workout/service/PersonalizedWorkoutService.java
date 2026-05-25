package com.vfit.modules.personalized_workout.service;

import com.vfit.modules.personalized_workout.dto.PersonalizedWorkoutResponse;

public interface PersonalizedWorkoutService {
    PersonalizedWorkoutResponse getPersonalizedWorkoutPlan(String userId);
}
