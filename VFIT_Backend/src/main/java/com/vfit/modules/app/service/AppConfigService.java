package com.vfit.modules.app.service;

import com.vfit.modules.app.dto.request.UpdateAppConfigRequest;
import com.vfit.modules.app.dto.response.AppConfigResponse;

public interface AppConfigService {
    String PUBLIC_CONFIG_KEY = "public";

    AppConfigResponse getPublicConfig();

    AppConfigResponse updatePublicConfig(UpdateAppConfigRequest request);
}
