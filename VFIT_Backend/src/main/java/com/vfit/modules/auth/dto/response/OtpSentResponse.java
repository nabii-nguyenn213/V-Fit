package com.vfit.modules.auth.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class OtpSentResponse {
    private final boolean success;
    private final String message;
    private final String email;
}
