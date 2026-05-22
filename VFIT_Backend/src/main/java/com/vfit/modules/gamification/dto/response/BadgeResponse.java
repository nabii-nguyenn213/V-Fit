package com.vfit.modules.gamification.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class BadgeResponse {
    private final String id;
    private final String name;
    private final String description;
    private final String iconUrl;
}
