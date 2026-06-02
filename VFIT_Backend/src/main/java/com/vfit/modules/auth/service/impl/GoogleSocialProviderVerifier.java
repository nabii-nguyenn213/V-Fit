package com.vfit.modules.auth.service.impl;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.modules.auth.dto.SocialLoginProvider;
import com.vfit.modules.auth.dto.SocialProviderProfile;
import com.vfit.modules.auth.service.SocialProviderVerifier;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Service
public class GoogleSocialProviderVerifier implements SocialProviderVerifier {
    private final RestClient restClient = RestClient.create();

    @Value("${auth.social.google.client-id:}")
    private String googleClientId;

    @Override
    public boolean supports(SocialLoginProvider provider) {
        return provider == SocialLoginProvider.GOOGLE;
    }

    @Override
    public SocialProviderProfile verify(String providerToken) {
        if (googleClientId == null || googleClientId.isBlank()) {
            throw new AppException(ErrorCode.SERVICE_UNAVAILABLE, "Google login is not configured");
        }

        try {
            Map<?, ?> body = restClient.get()
                    .uri("https://oauth2.googleapis.com/tokeninfo?id_token={token}", providerToken)
                    .retrieve()
                    .body(Map.class);

            if (body == null) {
                throw invalidToken();
            }

            String audience = asString(body.get("aud"));
            String subject = asString(body.get("sub"));
            String email = normalizeEmail(asString(body.get("email")));
            boolean emailVerified = "true".equalsIgnoreCase(asString(body.get("email_verified")));

            if (!googleClientId.equals(audience) || isBlank(subject) || isBlank(email) || !emailVerified) {
                throw invalidToken();
            }

            return SocialProviderProfile.builder()
                    .provider(SocialLoginProvider.GOOGLE)
                    .subject(subject)
                    .email(email)
                    .emailVerified(true)
                    .displayName(asString(body.get("name")))
                    .avatarUrl(asString(body.get("picture")))
                    .build();
        } catch (AppException e) {
            throw e;
        } catch (RestClientException e) {
            log.warn("[SECURITY AUDIT] Google token verification failed", e);
            throw invalidToken();
        }
    }

    private AppException invalidToken() {
        return new AppException(ErrorCode.UNAUTHORIZED, "Google login token is invalid");
    }

    private String asString(Object value) {
        return value == null ? null : value.toString();
    }

    private String normalizeEmail(String email) {
        return email == null ? null : email.toLowerCase().trim();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
