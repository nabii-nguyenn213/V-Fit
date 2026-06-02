package com.vfit.modules.auth.service;

import com.vfit.modules.auth.dto.SocialLoginProvider;
import com.vfit.modules.auth.dto.SocialProviderProfile;

public interface SocialProviderVerifier {
    boolean supports(SocialLoginProvider provider);

    SocialProviderProfile verify(String providerToken);
}
