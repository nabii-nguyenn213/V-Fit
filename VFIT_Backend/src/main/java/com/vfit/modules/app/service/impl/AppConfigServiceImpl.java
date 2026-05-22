package com.vfit.modules.app.service.impl;

import com.vfit.common.exception.ResourceNotFoundException;
import com.vfit.modules.app.document.AppConfig;
import com.vfit.modules.app.dto.request.UpdateAppConfigRequest;
import com.vfit.modules.app.dto.response.AppConfigResponse;
import com.vfit.modules.app.mapper.AppConfigMapper;
import com.vfit.modules.app.repository.AppConfigRepository;
import com.vfit.modules.app.service.AppConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AppConfigServiceImpl implements AppConfigService {
    private final AppConfigRepository appConfigRepository;
    private final AppConfigMapper appConfigMapper;

    @Override
    public AppConfigResponse getPublicConfig() {
        return appConfigRepository.findByConfigKey(PUBLIC_CONFIG_KEY)
                .map(appConfigMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("App config not found"));
    }

    @Override
    public AppConfigResponse updatePublicConfig(UpdateAppConfigRequest request) {
        AppConfig config = appConfigRepository.findByConfigKey(PUBLIC_CONFIG_KEY)
                .orElse(AppConfig.builder().configKey(PUBLIC_CONFIG_KEY).build());
        config.setAppName(request.getAppName());
        config.setSlogan(request.getSlogan());
        config.setSupportEmail(request.getSupportEmail());
        config.setTermsUrl(request.getTermsUrl());
        config.setPrivacyUrl(request.getPrivacyUrl());
        config.setLatestVersion(request.getLatestVersion());
        config.setMinSupportedVersion(request.getMinSupportedVersion());
        config.setMaintenanceMode(request.isMaintenanceMode());
        config.setMaintenanceMessage(request.getMaintenanceMessage());
        return appConfigMapper.toResponse(appConfigRepository.save(config));
    }
}
