package com.vfit.modules.gamification.service.impl;

import com.vfit.modules.gamification.dto.response.BadgeResponse;
import com.vfit.modules.gamification.dto.response.ChallengeResponse;
import com.vfit.modules.gamification.mapper.GamificationMapper;
import com.vfit.modules.gamification.repository.BadgeRepository;
import com.vfit.modules.gamification.repository.ChallengeRepository;
import com.vfit.modules.gamification.service.GamificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class GamificationServiceImpl implements GamificationService {
    private final BadgeRepository badgeRepository;
    private final ChallengeRepository challengeRepository;
    private final GamificationMapper gamificationMapper;

    @Override
    public Page<BadgeResponse> getBadges(Pageable pageable) {
        return badgeRepository.findAll(pageable).map(gamificationMapper::toBadgeResponse);
    }

    @Override
    public Page<ChallengeResponse> getActiveChallenges(Pageable pageable) {
        return challengeRepository.findByActiveTrue(pageable).map(gamificationMapper::toChallengeResponse);
    }
}
