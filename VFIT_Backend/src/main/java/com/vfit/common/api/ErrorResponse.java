package com.vfit.common.api;

import java.time.Instant;
import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ErrorResponse {
    private final boolean success = false;
    private final String code;
    private final String message;
    private final String path;
    private final List<String> details;
    private final Instant timestamp;
}
