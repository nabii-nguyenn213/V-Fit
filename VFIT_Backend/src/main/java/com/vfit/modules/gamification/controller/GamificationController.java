package com.vfit.modules.gamification.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.api.PageResponse;
import com.vfit.modules.gamification.dto.response.BadgeResponse;
import com.vfit.modules.gamification.dto.response.ChallengeResponse;
import com.vfit.modules.gamification.service.GamificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/gamification")
@RequiredArgsConstructor
public class GamificationController {
    private final GamificationService gamificationService;

    @GetMapping("/badges")
    public ApiResponse<PageResponse<BadgeResponse>> badges(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(PageResponse.from(gamificationService.getBadges(PageRequest.of(page, size))));
    }

    @GetMapping("/challenges")
    public ApiResponse<PageResponse<ChallengeResponse>> challenges(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(PageResponse.from(gamificationService.getActiveChallenges(PageRequest.of(page, size))));
    }
}
