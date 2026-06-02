package com.vfit.modules.auth.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class SocialProviderProfile {
    private final SocialLoginProvider provider;
    private final String subject;
    private final String email;
    private final boolean emailVerified;
    private final String displayName;
    private final String avatarUrl;
}
