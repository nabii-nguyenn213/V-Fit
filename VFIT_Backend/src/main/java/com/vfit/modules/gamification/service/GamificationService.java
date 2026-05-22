package com.vfit.modules.gamification.service;

import com.vfit.modules.gamification.dto.response.BadgeResponse;
import com.vfit.modules.gamification.dto.response.ChallengeResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface GamificationService {
    Page<BadgeResponse> getBadges(Pageable pageable);

    Page<ChallengeResponse> getActiveChallenges(Pageable pageable);
}
