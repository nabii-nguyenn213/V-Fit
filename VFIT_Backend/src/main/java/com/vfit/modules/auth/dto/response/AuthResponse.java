package com.vfit.modules.auth.dto.response;

import com.vfit.modules.user.dto.response.UserResponse;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AuthResponse {
    private final UserResponse user;
    private final TokenResponse tokens;
}
