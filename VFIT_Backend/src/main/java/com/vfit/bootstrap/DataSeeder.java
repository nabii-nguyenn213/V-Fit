package com.vfit.bootstrap;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.enums.DifficultyLevel;
import com.vfit.common.enums.GoalType;
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
import com.vfit.modules.personalized_workout.document.GoalWorkoutMetadata;
import com.vfit.modules.personalized_workout.repository.GoalWorkoutMetadataRepository;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

@Slf4j
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
    private final GoalWorkoutMetadataRepository goalWorkoutMetadataRepository;
    private final AppProperties appProperties;
    private final ObjectMapper objectMapper;

    @Override
    public void run(String... args) {
        log.info("[DataSeeder] Starting bootstrap seeding...");
        if (appProperties.getBootstrap().isAdminEnabled()) {
            log.info("[DataSeeder] Seeding admin account...");
            adminSeeder.seed();
        }
        if (appProperties.getBootstrap().isPublicConfigEnabled()) {
            log.info("[DataSeeder] Seeding public app config...");
            seedAppConfig();
        }

        // Critical production data — always run regardless of sample-data-enabled flag.
        // Both methods are idempotent: exercise catalog replaces by ID, workout metadata
        // always loads the latest expert plans.
        log.info("[DataSeeder] Seeding critical production data (exercise catalog + workout metadata)...");
        exerciseLibraryService.seedDefaultCatalog("vi-VN");
        log.info("[DataSeeder] Exercise catalog seeded.");
        seedPersonalizedWorkoutMetadata();
        log.info("[DataSeeder] Personalized workout metadata seeded.");

        if (appProperties.getBootstrap().isSampleDataEnabled()) {
            log.info("[DataSeeder] sample-data-enabled=true — running full seed...");
            adminSeeder.seedDemoUsers();
            seedExercises();
            log.info("[DataSeeder] Exercises seeded.");
            seedWorkoutPrograms();
            seedBadgesAndChallenges();
            seedFoods();
            log.info("[DataSeeder] All sample data seeded successfully.");
        } else {
            log.warn("[DataSeeder] sample-data-enabled=false — skipping demo users/exercise/food seed.");
        }
        log.info("[DataSeeder] Bootstrap complete.");
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
        long existing = exerciseRepository.count();
        if (existing > 0) {
            log.info("[DataSeeder] Deleting {} existing exercises before re-seeding...", existing);
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
        log.info("[DataSeeder] Inserted {} exercises into DB.", listToSave.size());
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

    private void seedPersonalizedWorkoutMetadata() {
        log.info("[DataSeeder] Seeding personalized workout metadata...");
        
        // Luôn làm sạch để nạp giáo án mới nhất của chuyên gia
        goalWorkoutMetadataRepository.deleteAll();

        // ----------------------------------------------------
        // 1. TĂNG CƠ (GAIN_MUSCLE)
        // ----------------------------------------------------
        GoalWorkoutMetadata.Rules gainMuscleRules = GoalWorkoutMetadata.Rules.builder()
                .compound(GoalWorkoutMetadata.RuleDetail.builder()
                        .reps("6-8 reps")
                        .rest("Nghỉ 2-4 phút")
                        .rir("Tập gần failure (RIR 1-2)")
                        .build())
                .isolation(GoalWorkoutMetadata.RuleDetail.builder()
                        .reps("10-15 reps")
                        .rest("Nghỉ 60-90 giây")
                        .rir("Có thể failure an toàn hơn")
                        .build())
                .build();

        GoalWorkoutMetadata.NutritionRecovery gainMuscleNutrition = GoalWorkoutMetadata.NutritionRecovery.builder()
                .caloriesTarget("+200-400 kcal/ngày (Calories surplus)")
                .proteinTarget("1.6-2.2g/kg cân nặng")
                .weightTarget("Tăng 0.25-0.5 kg/tuần")
                .sleepTarget("7-9 tiếng mỗi đêm")
                .waterTarget("2-3L/ngày")
                .build();

        Map<Integer, GoalWorkoutMetadata.DaySchedule> gainMuscleSchedule = new HashMap<>();

        // Thứ 2: PUSH (Monday = 1)
        gainMuscleSchedule.put(1, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 2")
                .dayType("PUSH (NGỰC, VAI, TAY SAU)")
                .restDay(false)
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-bench-press", 4, "6-8", "Ghế phẳng Barbell Bench Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-incline-bench-press", 3, "8-10", "Ghế dốc Incline Dumbbell Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-chest-fly-mid", 3, "12-15", "Ép ngực Cable Chest Fly"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-shoulder-press", 3, "8-10", "Vai Dumbbell Shoulder Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("overhead-tricep-extension", 3, "8-10", "Tay sau Overhead Tricep Extension"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("triceps-pushdown", 1, "12-15", "Tay sau Tricep Pushdown")
                ))
                .build());

        // Thứ 3: PULL (Tuesday = 2)
        gainMuscleSchedule.put(2, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 3")
                .dayType("PULL (LƯNG, TAY TRƯỚC)")
                .restDay(false)
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("lat-pulldown", 4, "8-10", "Xô Lat Pulldown"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-row", 3, "8-10", "Lưng Dumbbell Row"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("seated-cable-row", 3, "10-12", "Lưng Seated Cable Row"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("facepull-back", 3, "12-15", "Vai sau Face Pull"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-bayesian-curl", 3, "10-12", "Tay trước Cable Bayesian Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("incline-dumbbell-curl", 1, "10-12", "Tay trước Incline Dumbbell Curl")
                ))
                .build());

        // Thứ 4: LEG (Wednesday = 3)
        gainMuscleSchedule.put(3, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 4")
                .dayType("LEG (CHÂN, BẮP CHUỐI)")
                .restDay(false)
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-squat", 4, "6-8", "Đùi trước Barbell Squat"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-romanian-deadlift", 4, "8-10", "Đùi sau Romanian Deadlift"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("leg-press", 3, "10-12", "Chân đùi Leg Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("leg-curl", 3, "12-15", "Đùi sau Leg Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("leg-extension", 3, "12-15", "Đùi trước Leg Extension"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("smith-machine-for-calves", 4, "12-15", "Bắp chuối Smith Calf Raise")
                ))
                .build());

        // Thứ 5: NGHỈ (Thursday = 4)
        gainMuscleSchedule.put(4, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 5")
                .dayType("NGHỈ / CHẠY NHẸ")
                .restDay(true)
                .cardioAfterWorkout("Có thể chạy bộ nhẹ nhàng 20-30 phút phục hồi tích cực")
                .exercises(List.of())
                .build());

        // Thứ 6: UPPER (Friday = 5)
        gainMuscleSchedule.put(5, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 6")
                .dayType("UPPER (NỬA TRÊN CƠ THỂ)")
                .restDay(false)
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-incline-bench-press", 3, "8-10", "Ngực dốc Incline Barbell Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("pull-up", 3, "8-10", "Lưng Pull Up hoặc Lat Pulldown"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-row", 3, "8-10", "Lưng Barbell Row"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("machine-chest-fly", 4, "12-15", "Ngực Pec Deck / Machine Fly"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("reverse-fly", 3, "12-15", "Vai sau Reverse Machine Fly"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-shoulder-raise", 3, "12-15", "Vai giữa Cable Lateral Raise")
                ))
                .build());

        // Thứ 7: ARMS + SHOULDERS (Saturday = 6)
        gainMuscleSchedule.put(6, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 7")
                .dayType("ARMS + SHOULDERS (TAY & VAI)")
                .restDay(false)
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-lateral-raise", 4, "12-15", "Vai Dumbbell Lateral Raise"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-shoulder-raise", 3, "12-15", "Vai Cable Lateral Raise"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("rear-delt-fly", 3, "12-15", "Vai sau Rear Delt Fly"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("bicep-curl", 3, "8-10", "Tay trước Bicep Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("incline-dumbbell-curl", 3, "10-12", "Tay trước Incline Dumbbell Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("triceps-pushdown", 3, "12-15", "Tay sau Tricep Pushdown")
                ))
                .build());

        // Chủ nhật: NGHỈ (Sunday = 7)
        gainMuscleSchedule.put(7, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Chủ nhật")
                .dayType("NGHỈ PHỤC HỒI")
                .restDay(true)
                .exercises(List.of())
                .build());

        GoalWorkoutMetadata gainMuscleMetadata = GoalWorkoutMetadata.builder()
                .id(GoalType.GAIN_MUSCLE.name())
                .goalType(GoalType.GAIN_MUSCLE)
                .rules(gainMuscleRules)
                .nutritionRecovery(gainMuscleNutrition)
                .schedule(gainMuscleSchedule)
                .build();

        // ----------------------------------------------------
        // 2. GIẢM CÂN (LOSE_WEIGHT)
        // ----------------------------------------------------
        GoalWorkoutMetadata.Rules loseWeightRules = GoalWorkoutMetadata.Rules.builder()
                .compound(GoalWorkoutMetadata.RuleDetail.builder()
                        .reps("5-8 reps")
                        .rest("Nghỉ 2-3 phút")
                        .rir("Giữ sức mạnh tối đa")
                        .build())
                .isolation(GoalWorkoutMetadata.RuleDetail.builder()
                        .reps("10-15 reps")
                        .rest("Nghỉ 45-90 giây")
                        .rir("Tăng đốt calo và pump cơ")
                        .build())
                .build();

        GoalWorkoutMetadata.NutritionRecovery loseWeightNutrition = GoalWorkoutMetadata.NutritionRecovery.builder()
                .caloriesTarget("-300 đến -500 kcal/ngày (Calories deficit)")
                .proteinTarget("2.0-2.4g/kg cân nặng (bảo vệ cơ)")
                .weightTarget("Giảm 0.25-0.5 kg/tuần")
                .sleepTarget("7-9 tiếng mỗi đêm")
                .waterTarget("2.5-4L/ngày")
                .build();

        Map<Integer, GoalWorkoutMetadata.DaySchedule> loseWeightSchedule = new HashMap<>();

        // Thứ 2: PUSH (Monday = 1)
        loseWeightSchedule.put(1, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 2")
                .dayType("PUSH (NGỰC, VAI, TAY SAU)")
                .restDay(false)
                .cardioAfterWorkout("30-45 phút đi bộ dốc (Incline walking)")
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-bench-press", 4, "5-8", "Ngực Barbell Bench Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-incline-bench-press", 3, "8-10", "Ngực dốc Incline Dumbbell Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-chest-fly-mid", 3, "12-15", "Ép ngực Cable Chest Fly"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-shoulder-press", 3, "8-10", "Vai Dumbbell Shoulder Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("overhead-tricep-extension", 3, "10-12", "Tay sau Overhead Tricep Extension"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("triceps-pushdown", 3, "12-15", "Tay sau Tricep Pushdown")
                ))
                .build());

        // Thứ 3: PULL (Tuesday = 2)
        loseWeightSchedule.put(2, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 3")
                .dayType("PULL (LƯNG, VAI SAU, TAY TRƯỚC)")
                .restDay(false)
                .cardioAfterWorkout("30-45 phút đi bộ dốc (Incline walking)")
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("lat-pulldown", 4, "8-10", "Xô Lat Pulldown"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-row", 3, "8-10", "Lưng Dumbbell Row"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("seated-cable-row", 3, "10-12", "Lưng Seated Cable Row"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("facepull-back", 3, "12-15", "Vai sau Face Pull"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-bayesian-curl", 3, "10-12", "Tay trước Cable Bayesian Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("incline-dumbbell-curl", 3, "10-12", "Tay trước Incline Dumbbell Curl")
                ))
                .build());

        // Thứ 4: LEGS (Wednesday = 3)
        loseWeightSchedule.put(3, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 4")
                .dayType("LEGS (CHÂN)")
                .restDay(false)
                .cardioAfterWorkout("30-45 phút đi bộ dốc (Incline walking)")
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-squat", 4, "5-8", "Đùi trước Barbell Squat"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-romanian-deadlift", 4, "8-10", "Đùi sau Romanian Deadlift"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("leg-press", 3, "10-12", "Chân đùi Leg Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("leg-curl", 3, "12-15", "Đùi sau Leg Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("leg-extension", 3, "12-15", "Đùi trước Leg Extension"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("smith-machine-for-calves", 4, "12-15", "Bắp chuối Smith Calf Raise")
                ))
                .build());

        // Thứ 5: CARDIO + ABS (Thursday = 4)
        loseWeightSchedule.put(4, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 5")
                .dayType("CARDIO + ABS (CƠ BỤNG & CARDIO)")
                .restDay(false)
                .cardioAfterWorkout("90 phút đi bộ dốc đốt mỡ sâu")
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-crunch", 3, "12-15", "Bụng Cable Crunch"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-crunch", 3, "12-15", "Bụng dưới Hanging Knee Raise (co gối treo xà)"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-crunch", 3, "20", "Cơ liên sườn Russian Twist"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-crunch", 3, "45-60s", "Gồng bụng Plank tĩnh")
                ))
                .build());

        // Thứ 6: UPPER (Friday = 5)
        loseWeightSchedule.put(5, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 6")
                .dayType("UPPER (NỬA TRÊN CƠ THỂ)")
                .restDay(false)
                .cardioAfterWorkout("30-45 phút đi bộ dốc (Incline walking)")
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-incline-bench-press", 3, "8-10", "Ngực dốc Incline Barbell Press"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("pull-up", 3, "8-10", "Lưng Pull Up hoặc Lat Pulldown"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("barbell-row", 3, "8-10", "Lưng Barbell Row"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-shoulder-raise", 4, "12-15", "Vai giữa Cable Lateral Raise"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("machine-chest-fly", 3, "12-15", "Ngực Pec Deck / Machine Fly"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("reverse-fly", 3, "12-15", "Vai sau Reverse Machine Fly")
                ))
                .build());

        // Thứ 7: ARMS + SHOULDERS (Saturday = 6)
        loseWeightSchedule.put(6, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Thứ 7")
                .dayType("ARMS + SHOULDERS (TAY & VAI)")
                .restDay(false)
                .cardioAfterWorkout("Đi bộ nhanh phục hồi 15-20 phút")
                .exercises(List.of(
                        new GoalWorkoutMetadata.ExerciseItemMetadata("dumbbell-lateral-raise", 4, "12-15", "Vai Dumbbell Lateral Raise"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("cable-shoulder-raise", 3, "12-15", "Vai Cable Lateral Raise"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("rear-delt-fly", 3, "12-15", "Vai sau Rear Delt Fly"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("bicep-curl", 3, "8-10", "Tay trước Bicep Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("incline-dumbbell-curl", 3, "10-12", "Tay trước Incline Dumbbell Curl"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("lying-triceps-extensions", 3, "8-10", "Tay sau Skull Crusher"),
                        new GoalWorkoutMetadata.ExerciseItemMetadata("triceps-pushdown", 3, "12-15", "Tay sau Tricep Pushdown")
                ))
                .build());

        // Chủ nhật: NGHỈ (Sunday = 7)
        loseWeightSchedule.put(7, GoalWorkoutMetadata.DaySchedule.builder()
                .dayName("Chủ nhật")
                .dayType("NGHỈ PHỤC HỒI")
                .restDay(true)
                .exercises(List.of())
                .build());

        GoalWorkoutMetadata loseWeightMetadata = GoalWorkoutMetadata.builder()
                .id(GoalType.LOSE_WEIGHT.name())
                .goalType(GoalType.LOSE_WEIGHT)
                .rules(loseWeightRules)
                .nutritionRecovery(loseWeightNutrition)
                .schedule(loseWeightSchedule)
                .build();

        goalWorkoutMetadataRepository.saveAll(List.of(gainMuscleMetadata, loseWeightMetadata));
        log.info("[DataSeeder] Seeded 2 goal workout programs successfully.");
    }
}
