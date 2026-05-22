package com.vfit.modules.gamification.mapper;

import com.vfit.modules.gamification.document.Badge;
import com.vfit.modules.gamification.document.Challenge;
import com.vfit.modules.gamification.dto.response.BadgeResponse;
import com.vfit.modules.gamification.dto.response.ChallengeResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface GamificationMapper {
    BadgeResponse toBadgeResponse(Badge badge);

    ChallengeResponse toChallengeResponse(Challenge challenge);
}
