package com.vfit.modules.app.mapper;

import com.vfit.modules.app.document.AppConfig;
import com.vfit.modules.app.dto.response.AppConfigResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface AppConfigMapper {
    AppConfigResponse toResponse(AppConfig appConfig);
}
