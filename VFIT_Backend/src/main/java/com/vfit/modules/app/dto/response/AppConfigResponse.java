package com.vfit.modules.app.dto.response;

import java.time.Instant;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AppConfigResponse {
    private final String appName;
    private final String slogan;
    private final String supportEmail;
    private final String termsUrl;
    private final String privacyUrl;
    private final String latestVersion;
    private final String minSupportedVersion;
    private final boolean maintenanceMode;
    private final String maintenanceMessage;
    private final Instant updatedAt;
}
