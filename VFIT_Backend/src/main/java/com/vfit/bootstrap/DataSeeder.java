package com.vfit.bootstrap;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.enums.DifficultyLevel;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.modules.app.document.AppConfig;
import com.vfit.modules.app.repository.AppConfigRepository;
import com.vfit.modules.app.service.AppConfigService;
import com.vfit.modules.exercise.document.Exercise;
import com.vfit.modules.exercise.repository.ExerciseRepository;
import com.vfit.modules.exercise_library.service.ExerciseLibraryService;
import com.vfit.modules.gamification.document.Badge;
import com.vfit.modules.gamification.document.Challenge;
import com.vfit.modules.gamification.repository.BadgeRepository;
import com.vfit.modules.gamification.repository.ChallengeRepository;
import com.vfit.modules.nutrition.entity.Food;
import com.vfit.modules.nutrition.repository.FoodRepository;
import com.vfit.modules.workout.document.WorkoutProgram;
import com.vfit.modules.workout.repository.WorkoutProgramRepository;
import com.vfit.modules.exercise_library.document.ExerciseCatalog;
import com.vfit.modules.exercise_library.service.ExerciseCatalogSeedFactory;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {
    private final AdminSeeder adminSeeder;
    private final ExerciseRepository exerciseRepository;
    private final ExerciseLibraryService exerciseLibraryService;
    private final ExerciseCatalogSeedFactory seedFactory;
    private final WorkoutProgramRepository workoutProgramRepository;
    private final ChallengeRepository challengeRepository;
    private final BadgeRepository badgeRepository;
    private final FoodRepository foodRepository;
    private final AppConfigRepository appConfigRepository;
    private final AppProperties appProperties;
    private final ObjectMapper objectMapper;

    @Override
    public void run(String... args) {
        if (appProperties.getBootstrap().isAdminEnabled()) {
            adminSeeder.seed();
        }
        if (appProperties.getBootstrap().isPublicConfigEnabled()) {
            seedAppConfig();
        }
        if (appProperties.getBootstrap().isSampleDataEnabled()) {
            exerciseLibraryService.seedDefaultCatalog("vi-VN");
            seedExercises();
            seedWorkoutPrograms();
            seedBadgesAndChallenges();
            seedFoods();
        }
    }

    private void seedAppConfig() {
        if (appConfigRepository.existsByConfigKey(AppConfigService.PUBLIC_CONFIG_KEY)) {
            return;
        }
        AppProperties.Bootstrap.PublicConfig publicConfig =
                appProperties.getBootstrap().getPublicConfig();
        appConfigRepository.save(AppConfig.builder()
                .configKey(AppConfigService.PUBLIC_CONFIG_KEY)
                .appName(publicConfig.getAppName())
                .slogan(publicConfig.getSlogan())
                .supportEmail(publicConfig.getSupportEmail())
                .termsUrl(publicConfig.getTermsUrl())
                .privacyUrl(publicConfig.getPrivacyUrl())
                .latestVersion(publicConfig.getLatestVersion())
                .minSupportedVersion(publicConfig.getMinSupportedVersion())
                .maintenanceMode(false)
                .build());
    }

    private void seedExercises() {
        if (exerciseRepository.count() > 0) {
            exerciseRepository.deleteAll();
        }
        ExerciseCatalog catalog = seedFactory.defaultCatalog("vi-VN");
        List<Exercise> listToSave = new ArrayList<>();
        
        for (ExerciseCatalog.MuscleGroup group : catalog.getGroups()) {
            for (ExerciseCatalog.SubMuscleGroup subGroup : group.getSubGroups()) {
                for (ExerciseCatalog.ExerciseItem item : subGroup.getExercises()) {
                    List<String> instructionsList = new ArrayList<>();
                    if (item.getDescription() != null) {
                        for (String line : item.getDescription().split("(?<=\\.)\\s+")) {
                            if (line.trim().length() > 0) {
                                instructionsList.add(line.trim());
                            }
                        }
                    }
                    if (instructionsList.isEmpty()) {
                        instructionsList.add("Tập luyện có kiểm soát và giữ form chuẩn.");
                    }
                    
                    listToSave.add(Exercise.builder()
                            .id(item.getId())
                            .name(item.getName())
                            .muscleGroup(group.getName())
                            .difficulty(DifficultyLevel.BEGINNER)
                            .instructions(instructionsList)
                            .videoUrl(item.getVideoUrl())
                            .build());
                }
            }
        }
        exerciseRepository.saveAll(listToSave);
    }

    private void seedWorkoutPrograms() {
        if (workoutProgramRepository.count() > 0) {
            return;
        }
        workoutProgramRepository.saveAll(List.of(
                WorkoutProgram.builder()
                        .title("Beginner Full Body")
                        .difficulty(DifficultyLevel.BEGINNER)
                        .durationMinutes(30)
                        .exerciseIds(List.of())
                        .build(),
                WorkoutProgram.builder()
                        .title("Fat Burn Express")
                        .difficulty(DifficultyLevel.INTERMEDIATE)
                        .durationMinutes(25)
                        .exerciseIds(List.of())
                        .build(),
                WorkoutProgram.builder()
                        .title("Strength Foundation")
                        .difficulty(DifficultyLevel.BEGINNER)
                        .durationMinutes(40)
                        .exerciseIds(List.of())
                        .build()));
    }

    private void seedBadgesAndChallenges() {
        if (badgeRepository.count() == 0) {
            badgeRepository.saveAll(List.of(
                    Badge.builder()
                            .name("First Sweat")
                            .description("Complete the first workout")
                            .iconUrl("/badges/first-sweat.png")
                            .build(),
                    Badge.builder()
                            .name("Consistency Starter")
                            .description("Complete three workouts")
                            .iconUrl("/badges/consistency.png")
                            .build()));
        }
        if (challengeRepository.count() == 0) {
            challengeRepository.saveAll(List.of(
                    Challenge.builder()
                            .title("3-Day Starter")
                            .targetValue(3)
                            .xpReward(100)
                            .badgeName("Consistency Starter")
                            .build(),
                    Challenge.builder()
                            .title("Core Control")
                            .targetValue(5)
                            .xpReward(150)
                            .badgeName("First Sweat")
                            .build(),
                    Challenge.builder()
                            .title("Weekly Momentum")
                            .targetValue(7)
                            .xpReward(250)
                            .badgeName("Consistency Starter")
                            .build()));
        }
    }

    private void seedFoods() {
        try {
            ClassPathResource resource = new ClassPathResource("db/foods.seed.json");
            List<Food> foods = objectMapper.readValue(
                    resource.getInputStream(),
                    new TypeReference<>() {});
            foodRepository.saveAll(foods);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to seed nutrition foods", ex);
        }
    }
}
