package com.vfit.modules.app.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateAppConfigRequest {
    @NotBlank
    @Size(max = 80)
    private String appName;
    @Size(max = 180)
    private String slogan;
    @Email
    private String supportEmail;
    private String termsUrl;
    private String privacyUrl;
    private String latestVersion;
    private String minSupportedVersion;
    private boolean maintenanceMode;
    @Size(max = 300)
    private String maintenanceMessage;
}
