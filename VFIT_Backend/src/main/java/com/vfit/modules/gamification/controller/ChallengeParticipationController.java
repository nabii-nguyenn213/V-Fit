package com.vfit.modules.gamification.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.gamification.document.UserChallengeParticipation;
import com.vfit.modules.gamification.service.ChallengeParticipationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/gamification/challenges")
@RequiredArgsConstructor
@Tag(name = "Gamification Challenges", description = "Endpoints for managing user progress photo challenges and rewards")
public class ChallengeParticipationController {

    private static final ZoneId ZONE_VN = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private final ChallengeParticipationService participationService;

    @PostMapping("/{challengeId}/join")
    @Operation(summary = "Join a new challenge or rejoin a failed one")
    public ApiResponse<UserChallengeParticipation> joinChallenge(@PathVariable("challengeId") String challengeId) {
        String userId = SecurityUtil.requireCurrentUserId();
        return ApiResponse.ok(participationService.joinChallenge(userId, challengeId));
    }

    @PostMapping("/{challengeId}/revive")
    @Operation(summary = "Revive a broken streak using 150 V-Points")
    public ApiResponse<UserChallengeParticipation> reviveStreak(@PathVariable("challengeId") String challengeId) {
        String userId = SecurityUtil.requireCurrentUserId();
        return ApiResponse.ok(participationService.reviveStreak(userId, challengeId));
    }

    @GetMapping("/{challengeId}/participation")
    @Operation(summary = "Get the user's participation status for a specific challenge")
    public ApiResponse<UserChallengeParticipation> getParticipation(@PathVariable("challengeId") String challengeId) {
        String userId = SecurityUtil.requireCurrentUserId();
        return ApiResponse.ok(participationService.getParticipation(userId, challengeId));
    }

    @GetMapping("/active-participations")
    @Operation(summary = "Get all active challenge participations for the current user")
    public ApiResponse<List<UserChallengeParticipation>> getActiveParticipations() {
        String userId = SecurityUtil.requireCurrentUserId();
        return ApiResponse.ok(participationService.getActiveParticipations(userId));
    }

    /**
     * Called by Flutter when the user completes ALL exercises for the day.
     * Increments streak on every active challenge participation (idempotent per day).
     */
    @PostMapping("/workout-checkin")
    @Operation(summary = "Log a completed workout day — updates challenge streaks for all active participations")
    public ApiResponse<Map<String, String>> workoutCheckin() {
        String userId = SecurityUtil.requireCurrentUserId();
        String todayVn = LocalDate.now(ZONE_VN).format(DATE_FMT);
        participationService.recordWorkoutCheckin(userId, todayVn);
        return ApiResponse.ok(Map.of("date", todayVn, "status", "checked_in"));
    }
}
