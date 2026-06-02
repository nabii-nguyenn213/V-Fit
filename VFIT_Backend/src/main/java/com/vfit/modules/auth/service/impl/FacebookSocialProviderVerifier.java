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
public class FacebookSocialProviderVerifier implements SocialProviderVerifier {
    private final RestClient restClient = RestClient.create();

    @Value("${auth.social.facebook.app-id:}")
    private String facebookAppId;

    @Value("${auth.social.facebook.app-secret:}")
    private String facebookAppSecret;

    @Override
    public boolean supports(SocialLoginProvider provider) {
        return provider == SocialLoginProvider.FACEBOOK;
    }

    @Override
    public SocialProviderProfile verify(String providerToken) {
        if (facebookAppId == null || facebookAppId.isBlank()
                || facebookAppSecret == null || facebookAppSecret.isBlank()) {
            throw new AppException(ErrorCode.SERVICE_UNAVAILABLE, "Facebook login is not configured");
        }

        try {
            Map<?, ?> debugBody = restClient.get()
                    .uri("https://graph.facebook.com/debug_token?input_token={inputToken}&access_token={appToken}",
                            providerToken, facebookAppId + "|" + facebookAppSecret)
                    .retrieve()
                    .body(Map.class);
            Map<?, ?> debugData = nestedMap(debugBody, "data");

            String appId = asString(debugData.get("app_id"));
            String userId = asString(debugData.get("user_id"));
            boolean valid = Boolean.TRUE.equals(debugData.get("is_valid"));
            if (!valid || !facebookAppId.equals(appId) || isBlank(userId)) {
                throw invalidToken();
            }

            Map<?, ?> profile = restClient.get()
                    .uri("https://graph.facebook.com/me?fields=id,name,email,picture&access_token={token}", providerToken)
                    .retrieve()
                    .body(Map.class);

            String subject = asString(profile == null ? null : profile.get("id"));
            String email = normalizeEmail(asString(profile == null ? null : profile.get("email")));
            if (!userId.equals(subject) || isBlank(email)) {
                throw new AppException(ErrorCode.BAD_REQUEST, "Facebook account must provide a verified email");
            }

            return SocialProviderProfile.builder()
                    .provider(SocialLoginProvider.FACEBOOK)
                    .subject(subject)
                    .email(email)
                    .emailVerified(true)
                    .displayName(asString(profile.get("name")))
                    .avatarUrl(extractPictureUrl(profile))
                    .build();
        } catch (AppException e) {
            throw e;
        } catch (RestClientException e) {
            log.warn("[SECURITY AUDIT] Facebook token verification failed", e);
            throw invalidToken();
        }
    }

    private AppException invalidToken() {
        return new AppException(ErrorCode.UNAUTHORIZED, "Facebook login token is invalid");
    }

    private Map<?, ?> nestedMap(Map<?, ?> body, String key) {
        Object value = body == null ? null : body.get(key);
        if (value instanceof Map<?, ?> map) {
            return map;
        }
        throw invalidToken();
    }

    private String extractPictureUrl(Map<?, ?> profile) {
        Object picture = profile == null ? null : profile.get("picture");
        if (!(picture instanceof Map<?, ?> pictureMap)) {
            return null;
        }
        Object data = pictureMap.get("data");
        if (!(data instanceof Map<?, ?> dataMap)) {
            return null;
        }
        return asString(dataMap.get("url"));
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
