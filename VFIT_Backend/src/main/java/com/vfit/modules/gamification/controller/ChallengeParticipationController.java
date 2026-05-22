package com.vfit.modules.gamification.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.gamification.document.UserChallengeParticipation;
import com.vfit.modules.gamification.service.ChallengeParticipationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/gamification/challenges")
@RequiredArgsConstructor
@Tag(name = "Gamification Challenges", description = "Endpoints for managing user progress photo challenges and rewards")
public class ChallengeParticipationController {

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
}
