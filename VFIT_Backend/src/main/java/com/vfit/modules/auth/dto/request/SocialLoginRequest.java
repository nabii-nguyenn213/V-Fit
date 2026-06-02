package com.vfit.modules.auth.dto.request;

import com.vfit.modules.auth.dto.SocialLoginProvider;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SocialLoginRequest {
    @NotNull
    private SocialLoginProvider provider;

    @NotBlank
    private String providerToken;

    private String nonce;
    private String platform;
}
