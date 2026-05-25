package com.vfit.modules.auth.dto.response;

import java.time.Instant;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ActiveSessionResponse {
    private final String id;
    private final String deviceId;
    private final String userAgent;
    private final String ipAddress;
    private final Instant expiresAt;
    private final Instant createdAt;
}
